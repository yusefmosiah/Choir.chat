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
                    .padding([.horizontal], 1) // Reduced horizontal padding
                    .padding(.top, 1) // Reduced top padding
                    .padding(.bottom, 0) // No bottom padding
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .fixedSize(horizontal: false, vertical: true) // Allow content to use its natural height
                    .drawingGroup(opaque: false)
                    .environment(\.layoutDirection, .leftToRight) // Ensure consistent layout
                    .environment(\.lineLimit, nil) // Ensure no line limits
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

    private func fetchVectorFromAPI(vectorId: String, message: Message) {
        // Check if we have citation explanations for this vector
        var citationExplanation: String? = nil
        var citationReward: [String: Any]? = nil

        // Look for citation explanations in the message
        if let explanations = message.citationExplanations, let explanation = explanations[vectorId] {
            citationExplanation = explanation
        }

        // Look for citation reward in the message
        if let reward = message.citationReward, reward["success"] as? Bool == true {
            citationReward = reward
        }

        // Show loading content
        let loadingContent = """
        # Loading Vector Content

        Fetching full content for vector ID: V\(vectorId.prefix(8))...

        Please wait...
        """

        // Show the vector sheet with citation information if available
        if citationExplanation != nil || citationReward != nil {
            TextSelectionManager.shared.showVectorSheetWithCitation(
                withText: loadingContent,
                vectorId: vectorId,
                explanation: citationExplanation,
                reward: citationReward
            )
        } else {
            TextSelectionManager.shared.showVectorSheet(withText: loadingContent, vectorId: vectorId)
        }

        // Check if we have a local match in the message's vector results
        let localMatch = message.vectorSearchResults.first(where: { $0.id == vectorId })

        if let localMatch = localMatch {
            let previewContent = formatVectorResult(localMatch, index: -1, source: "local (loading full content...)")
            TextSelectionManager.shared.updateVectorSheet(withText: previewContent, vectorId: vectorId)
        }

        // Fetch the vector from the API
        VectorService.shared.fetchVector(vectorId: vectorId) { success, vectorResult, errorMessage in
            if success, let vectorResult = vectorResult {
                // Format and display the vector result
                let formattedContent = formatVectorResult(vectorResult, index: -1, source: "api")
                TextSelectionManager.shared.updateVectorSheet(withText: formattedContent, vectorId: vectorId)
            } else if let localMatch = localMatch {
                // If API fetch failed but we have a local match, use that
                let formattedContent = formatVectorResult(localMatch, index: -1, source: "local")
                TextSelectionManager.shared.updateVectorSheet(withText: formattedContent, vectorId: vectorId)
            } else {
                // Display error message
                let errorContent: String

                if errorMessage?.contains("not found") == true {
                    errorContent = """
                    # Vector Not Found

                    The vector with ID V\(vectorId.prefix(8)) could not be found.

                    This may be because:
                    - The vector ID is incorrect
                    - The vector has been deleted
                    - The vector is not accessible to your account

                    Please try a different vector reference.
                    """
                } else {
                    errorContent = """
                    # Error Fetching Vector Content

                    Failed to fetch content for vector ID: \(vectorId)

                    Error: \(errorMessage ?? "Unknown error")
                    """
                }

                TextSelectionManager.shared.updateVectorSheet(withText: errorContent, vectorId: vectorId)
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
