import SwiftUI
import MarkdownUI

struct PaginatedMarkdownView: View {
    let pageContent: String
    var onNavigateToPreviousPhase: (() -> Void)?
    var onNavigateToNextPhase: (() -> Void)?
    var currentMessage: Message? // Parent message

    @StateObject private var textSelectionManager = TextSelectionManager.shared

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Color.clear)

            if !pageContent.isEmpty {
                Markdown(pageContent)
                    .markdownTheme(.normalizedHeadings)
                    .padding([.horizontal], 2)
                    .padding(.top, 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .drawingGroup(opaque: false)
                    .onOpenURL { url in
                        handleLinkTap(url)
                    }
                    .onLongPressGesture {
                        TextSelectionManager.shared.showSheet(withText: pageContent)
                    }
            } else {
                Text("").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func handleLinkTap(_ url: URL) {
        guard let scheme = url.scheme else { return }

        // Handle internal choir:// deep links
        if scheme == "choir" {
            guard let host = url.host else { return }

            switch host {
            case "vector":
                // Extract vector ID from the path
                let vectorId = url.lastPathComponent
                if !vectorId.isEmpty {
                    handleVectorDeepLink(vectorId: vectorId)
                }
            case "thread":
                // Handle thread links (already implemented elsewhere)
                break
            default:
                break
            }
        } else {
            // Open external URLs in Safari
            UIApplication.shared.open(url)
        }
    }

    private func handleVectorDeepLink(vectorId: String) {
        guard let message = currentMessage else {
            TextSelectionManager.shared.showSheet(withText: "Unable to display vector result: No message context available.")
            return
        }

        if let indexNumber = Int(vectorId) {
            handleLegacyVectorReference(indexNumber: indexNumber, message: message)
        } else {
            fetchVectorFromAPI(vectorId: vectorId, message: message)
        }
    }

    private func handleLegacyVectorReference(indexNumber: Int, message: Message) {
        var vectorResult: VectorSearchResult? = nil

        if indexNumber > 0 && indexNumber <= message.vectorSearchResults.count {
            vectorResult = message.vectorSearchResults[indexNumber - 1]
        }

        if vectorResult == nil {
            vectorResult = message.vectorSearchResults.first { result in
                guard let resultId = result.id else { return false }
                return resultId.contains(String(indexNumber)) || resultId.contains("#\(indexNumber)")
            }
        }

        if let vectorResult = vectorResult {
            displayVectorResult(vectorResult, index: indexNumber)
            return
        }

        if !message.vectorSearchResults.isEmpty {
            let availableContent = message.vectorSearchResults.map { result in
                """
                - ID: \(result.id ?? "nil")
                  Content: \(result.content.prefix(50))...
                """
            }.joined(separator: "\n")

            let fallbackContent = """
            # Vector Reference #\(indexNumber) Not Found

            Couldn't find exact match, but here are available vector results:

            \(availableContent)

            ## Debug Info
            - Message ID: \(message.id)
            - Current phase: \(message.selectedPhase.rawValue)
            - Vector results count: \(message.vectorSearchResults.count)
            """

            TextSelectionManager.shared.showSheet(withText: fallbackContent)
        } else {
            let diagnosticContent = """
            # No Vector Results Available

            The reference **#\(indexNumber)** could not be displayed because no vector data is available.

            ## Debug Info
            - Message ID: \(message.id)
            - Current phase: \(message.selectedPhase.rawValue)
            """

            TextSelectionManager.shared.showSheet(withText: diagnosticContent)
        }
    }

    private static var activeVectorRequests: Set<String> = []

    private func fetchVectorFromAPI(vectorId: String, message: Message) {
        if Self.activeVectorRequests.contains(vectorId) {
            return
        }

        Self.activeVectorRequests.insert(vectorId)

        let loadingContent = """
        # Loading Vector Content

        Fetching full content for vector ID: V\(vectorId.prefix(8))...

        Please wait...
        """
        TextSelectionManager.shared.showVectorSheet(withText: loadingContent, vectorId: vectorId)

        let localMatch = message.vectorSearchResults.first(where: { $0.id == vectorId })

        if let localMatch = localMatch {
            let previewContent = formatVectorResult(localMatch, index: -1, source: "local (loading full content...)")
            TextSelectionManager.shared.updateVectorSheet(withText: previewContent, vectorId: vectorId)
        }

        Task {
            do {
                let url = ApiConfig.url(for: "\(ApiConfig.Endpoints.vectors)/\(vectorId)")
                var request = URLRequest(url: url)
                request.httpMethod = "GET"

                if let authToken = UserDefaults.standard.string(forKey: "authToken") {
                    request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                }

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "Invalid response", code: 0)
                }

                if httpResponse.statusCode == 404 {
                    if let localMatch = localMatch {
                        let formattedContent = formatVectorResult(localMatch, index: -1, source: "local")
                        await MainActor.run {
                            TextSelectionManager.shared.updateVectorSheet(withText: formattedContent, vectorId: vectorId)
                            Self.activeVectorRequests.remove(vectorId)
                        }
                        return
                    } else {
                        let errorContent = """
                        # Vector Not Found

                        The vector with ID V\(vectorId.prefix(8)) could not be found.

                        This may be because:
                        - The vector ID is incorrect
                        - The vector has been deleted
                        - The vector is not accessible to your account

                        Please try a different vector reference.
                        """

                        await MainActor.run {
                            TextSelectionManager.shared.updateVectorSheet(withText: errorContent, vectorId: vectorId)
                            Self.activeVectorRequests.remove(vectorId)
                        }
                        return
                    }
                }

                guard httpResponse.statusCode == 200 else {
                    throw NSError(domain: "Invalid response", code: httpResponse.statusCode)
                }

                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(APIResponse<VectorResult>.self, from: data)

                guard apiResponse.success, let vectorData = apiResponse.data else {
                    throw NSError(domain: apiResponse.message ?? "Unknown error", code: 0)
                }

                let vectorResult = VectorSearchResult(
                    content: vectorData.content,
                    score: 1.0,
                    provider: "qdrant",
                    metadata: vectorData.metadata?.compactMapValues { $0 as? String },
                    id: vectorData.id,
                    content_preview: nil
                )

                let formattedContent = formatVectorResult(vectorResult, index: -1, source: "api")

                await MainActor.run {
                    TextSelectionManager.shared.updateVectorSheet(withText: formattedContent, vectorId: vectorId)
                    Self.activeVectorRequests.remove(vectorId)
                }

            } catch {
                let errorContent = """
                # Error Fetching Vector Content

                Failed to fetch content for vector ID: \(vectorId)

                Error: \(error.localizedDescription)
                """

                await MainActor.run {
                    TextSelectionManager.shared.updateVectorSheet(withText: errorContent, vectorId: vectorId)
                    Self.activeVectorRequests.remove(vectorId)
                }
            }
        }
    }

    private func formatVectorResult(_ vectorResult: VectorSearchResult, index: Int, source: String = "local") -> String {
        var formattedContent = """
        # Vector Result
        """

        if index > 0 {
            formattedContent = """
            # Vector Result #\(index)
            """
        }

        let sourceInfo = source == "api" ? "(from API)" : "(from local cache)"
        formattedContent += " \(sourceInfo)"

        if let id = vectorResult.id {
            let shortId = id.prefix(8)
            formattedContent += "\nID: V\(shortId)..."
        }

        if source == "local" && vectorResult.content.count < 1000 {
            formattedContent += "\n\n**Note:** This content may be truncated. The full content is being fetched from the API."
        }

        let contentToDisplay = vectorResult.content

        formattedContent += """

        ---

        \(contentToDisplay)
        """

        return formattedContent
    }

    private func displayVectorResult(_ vectorResult: VectorSearchResult, index: Int, source: String = "local") {
        let formattedContent = formatVectorResult(vectorResult, index: index, source: source)

        if let id = vectorResult.id {
            TextSelectionManager.shared.showVectorSheet(withText: formattedContent, vectorId: id)
        } else {
            TextSelectionManager.shared.showSheet(withText: formattedContent)
        }
    }
}
