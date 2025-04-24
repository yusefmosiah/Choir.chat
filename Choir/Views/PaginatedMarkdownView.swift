import SwiftUI
import MarkdownUI

struct PaginatedMarkdownView: View {
    let markdownText: String
    let availableSize: CGSize
    @Binding var currentPage: Int
    var onNavigateToPreviousPhase: (() -> Void)?
    var onNavigateToNextPhase: (() -> Void)?
    var currentMessage: Message? // Parent message

    // Cache structure to store pagination results
    private struct PaginationCache: Equatable {
        let text: String
        let width: CGFloat
        let height: CGFloat
        let pages: [String]

        static func == (lhs: PaginationCache, rhs: PaginationCache) -> Bool {
            lhs.text == rhs.text &&
            abs(lhs.width - rhs.width) < 1.0 &&
            abs(lhs.height - rhs.height) < 1.0
        }
    }

    @State private var pages: [String] = []
    @State private var totalPages: Int = 1
    @State private var showingActionSheet = false
    @StateObject private var textSelectionManager = TextSelectionManager.shared

    // Cache for pagination results
    @State private var cache: PaginationCache?

    // Task for background pagination
    @State private var paginationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Color.clear)

                    if pages.indices.contains(currentPage) {
                        markdownPageView(pages[currentPage])
                    } else if !markdownText.isEmpty {
                        ProgressView()
                    } else {
                        Text("").frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .onLongPressGesture {
                    let currentText = extractCurrentPageText()
                    if !currentText.isEmpty {
                        TextSelectionManager.shared.showSheet(withText: markdownText)
                    }
                }

                // Pagination controls are now handled by GlassPageControl
            }
            .onAppear {
                paginateContent(size: geometry.size)
            }
            .onChange(of: markdownText) { _, newText in
                paginateContent(size: geometry.size)
            }
            // Debounce size changes to avoid excessive pagination
            .onChange(of: geometry.size) { _, newSize in
                // Cancel any pending pagination task
                paginationTask?.cancel()

                // Create a new debounced task after a short delay
                paginationTask = Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
                    if !Task.isCancelled {
                        await MainActor.run {
                            paginateContent(size: newSize)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func markdownPageView(_ textPage: String) -> some View {
        // The text is already processed for vector references during pagination
        Markdown(textPage)
            .markdownTheme(.normalizedHeadings)
            .padding([.horizontal], 2) // Reduce horizontal padding
            .padding(.top, 2) // Reduce top padding
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // Add drawing group to leverage Metal rendering
            .drawingGroup(opaque: false)
            // Handle URL opening events
            .onOpenURL { url in
                handleLinkTap(url)
            }
    }

    private func paginateContent(size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            // Process links even for single page
            let processedText = markdownText.convertVectorReferencesToDeepLinks()
            pages = [processedText]
            totalPages = 1
            currentPage = 0
            return
        }

        // First convert vector references to deep links
        let processedText = markdownText.convertVectorReferencesToDeepLinks()

        // Then optimize the text for pagination by replacing long vector IDs with shorter placeholders
        let (optimizedText, idMapping) = processedText.optimizeForPagination()

        // Check if we have a valid cache that matches current parameters
        let potentialCache = PaginationCache(
            text: markdownText, // Use original text for cache key
            width: size.width,
            height: size.height,
            pages: []
        )

        if let existingCache = cache, existingCache == potentialCache {
            // Use cached pages
            pages = existingCache.pages
        } else {
            // Calculate new pages with the optimized text
            var optimizedPages = splitMarkdownIntoPages(optimizedText, size: size)

            // Restore the original vector IDs in each page
            let restoredPages = optimizedPages.map { page in
                return page.restoreVectorIds(idMapping: idMapping)
            }

            pages = restoredPages

            // Store the result in cache
            cache = PaginationCache(
                text: markdownText, // Still use original text for cache key
                width: size.width,
                height: size.height,
                pages: restoredPages
            )
        }

        totalPages = max(1, pages.count)

        // Ensure currentPage is within bounds
        if currentPage >= totalPages {
            currentPage = max(0, totalPages - 1)
        } else if currentPage < 0 {
            currentPage = 0
        }

        // Debug logging to help diagnose pagination issues
        print("Pagination: \(totalPages) pages created for size \(size)")
    }

    private func splitMarkdownIntoPages(_ text: String, size: CGSize) -> [String] {
        guard !text.isEmpty else { return [""] }
        guard size.width > 8, size.height > 40 else {
            return [text]
        }

        let measurer = TextMeasurer(sizeCategory: .medium)
        // Use minimal vertical padding to maximize content
        let verticalPadding: CGFloat = 4
        let availableTextHeight = size.height - verticalPadding

        guard availableTextHeight > 20 else {
            return [text]
        }

        // Use slightly more width to maximize content
        let availableTextWidth = size.width - 4

        // Use the new MarkdownPaginator to handle pagination with formatting preservation
        let paginator = MarkdownPaginator(textMeasurer: measurer)
        let pagesResult = paginator.paginateMarkdown(
            text,
            width: availableTextWidth,
            height: availableTextHeight
        )

        if pagesResult.isEmpty && !text.isEmpty {
            return [text]
        }
        if pagesResult.isEmpty && text.isEmpty {
            return [""]
        }

        // Debug logging to help diagnose pagination issues
        print("Split text into \(pagesResult.count) pages")

        return pagesResult
    }

    private func extractCurrentPageText() -> String {
        guard pages.indices.contains(currentPage) else { return "" }
        return pages[currentPage]
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
                } else {
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
        // Use the message passed to this view
        guard let message = currentMessage else {
            TextSelectionManager.shared.showSheet(withText: "Unable to display vector result: No message context available.")
            return
        }

        // Check if this is a numeric ID (legacy format) or a vector ID (new format)
        if let indexNumber = Int(vectorId) {
            // Legacy format - try to find by position
            handleLegacyVectorReference(indexNumber: indexNumber, message: message)
        } else {
            // New format - try to find by actual vector ID
            fetchVectorFromAPI(vectorId: vectorId, message: message)
        }
    }

    private func handleLegacyVectorReference(indexNumber: Int, message: Message) {
        // Try to find the vector result with the matching index
        var vectorResult: VectorSearchResult? = nil

        // First try direct index lookup
        if indexNumber > 0 && indexNumber <= message.vectorSearchResults.count {
            vectorResult = message.vectorSearchResults[indexNumber - 1]
        }

        // If not found, try to find by ID if available
        if vectorResult == nil {
            vectorResult = message.vectorSearchResults.first { result in
                guard let resultId = result.id else { return false }
                return resultId.contains(String(indexNumber)) || resultId.contains("#\(indexNumber)")
            }
        }

        // If we found a vector result, display it
        if let vectorResult = vectorResult {
            displayVectorResult(vectorResult, index: indexNumber)
            return
        }

        // If no results found, show available content
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
            // No vector results at all
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

    // Track active API requests to prevent duplicates
    private static var activeVectorRequests: Set<String> = []

    private func fetchVectorFromAPI(vectorId: String, message: Message) {
        // Check if we're already fetching this vector
        if Self.activeVectorRequests.contains(vectorId) {
            return
        }

        // Add to active requests
        Self.activeVectorRequests.insert(vectorId)

        // Show loading indicator immediately
        let loadingContent = """
        # Loading Vector Content

        Fetching full content for vector ID: V\(vectorId.prefix(8))...

        Please wait...
        """
        TextSelectionManager.shared.showVectorSheet(withText: loadingContent, vectorId: vectorId)

        // Check if we have a local match to use as fallback if API call fails
        let localMatch = message.vectorSearchResults.first(where: { $0.id == vectorId })

        // If we have a local match, show it immediately while we fetch the full content
        if let localMatch = localMatch {
            let previewContent = formatVectorResult(localMatch, index: -1, source: "local (loading full content...)")
            TextSelectionManager.shared.updateVectorSheet(withText: previewContent, vectorId: vectorId)
        }

        // Fetch from API
        Task {
            do {
                // Create URL for the vector API endpoint
                let url = ApiConfig.url(for: "\(ApiConfig.Endpoints.vectors)/\(vectorId)")

                // Create request
                var request = URLRequest(url: url)
                request.httpMethod = "GET"

                // Add authorization header if available
                if let authToken = UserDefaults.standard.string(forKey: "authToken") {
                    request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                }

                // Make the request
                let (data, response) = try await URLSession.shared.data(for: request)

                // Check response status
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "Invalid response", code: 0)
                }

                // If we get a 404, the vector doesn't exist
                // Use the local match if available
                if httpResponse.statusCode == 404 {
                    if let localMatch = localMatch {
                        // Format the local match content
                        let formattedContent = formatVectorResult(localMatch, index: -1, source: "local")

                        // Update the sheet with the local content
                        await MainActor.run {
                            TextSelectionManager.shared.updateVectorSheet(withText: formattedContent, vectorId: vectorId)
                            // Remove from active requests
                            Self.activeVectorRequests.remove(vectorId)
                        }
                        return
                    } else {
                        // No match found, show an error message
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
                            // Remove from active requests
                            Self.activeVectorRequests.remove(vectorId)
                        }
                        return
                    }
                }

                // For other errors, throw an exception
                guard httpResponse.statusCode == 200 else {
                    throw NSError(domain: "Invalid response", code: httpResponse.statusCode)
                }

                // Parse the response
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(APIResponse<VectorResult>.self, from: data)

                // Check if the response was successful
                guard apiResponse.success, let vectorData = apiResponse.data else {
                    throw NSError(domain: apiResponse.message ?? "Unknown error", code: 0)
                }

                // Create a VectorSearchResult from the API response
                let vectorResult = VectorSearchResult(
                    content: vectorData.content,
                    score: 1.0, // Default score for direct fetches
                    provider: "qdrant",
                    metadata: vectorData.metadata?.compactMapValues { $0 as? String },
                    id: vectorData.id,
                    content_preview: nil
                )

                // Format the result content
                let formattedContent = formatVectorResult(vectorResult, index: -1, source: "api")

                // Update the sheet with the fetched content
                await MainActor.run {
                    TextSelectionManager.shared.updateVectorSheet(withText: formattedContent, vectorId: vectorId)
                    // Remove from active requests
                    Self.activeVectorRequests.remove(vectorId)
                }

            } catch {
                // Show error
                let errorContent = """
                # Error Fetching Vector Content

                Failed to fetch content for vector ID: \(vectorId)

                Error: \(error.localizedDescription)
                """

                await MainActor.run {
                    TextSelectionManager.shared.updateVectorSheet(withText: errorContent, vectorId: vectorId)
                    // Remove from active requests
                    Self.activeVectorRequests.remove(vectorId)
                }
            }
        }
    }

    private func formatVectorResult(_ vectorResult: VectorSearchResult, index: Int, source: String = "local") -> String {
        // Format initial content with minimal metadata
        var formattedContent = """
        # Vector Result
        """

        // Add index if it's a position-based reference
        if index > 0 {
            formattedContent = """
            # Vector Result #\(index)
            """
        }

        // Add source information
        let sourceInfo = source == "api" ? "(from API)" : "(from local cache)"
        formattedContent += " \(sourceInfo)"

        // Add ID if available (just the shortened version)
        if let id = vectorResult.id {
            let shortId = id.prefix(8)
            formattedContent += "\nID: V\(shortId)..."
        }

        // Add note about content source
        if source == "local" && vectorResult.content.count < 1000 {
            formattedContent += "\n\n**Note:** This content may be truncated. The full content is being fetched from the API."
        }

        // Use best available content version
        let contentToDisplay = vectorResult.content

        formattedContent += """

        ---

        \(contentToDisplay)
        """

        return formattedContent
    }

    private func displayVectorResult(_ vectorResult: VectorSearchResult, index: Int, source: String = "local") {
        // Format the content
        let formattedContent = formatVectorResult(vectorResult, index: index, source: source)

        // Show the content in a text selection sheet
        if let id = vectorResult.id {
            TextSelectionManager.shared.showVectorSheet(withText: formattedContent, vectorId: id)
        } else {
            TextSelectionManager.shared.showSheet(withText: formattedContent)
        }
    }
}
