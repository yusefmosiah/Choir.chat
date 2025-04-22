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

                Spacer(minLength: 0)

                // Pagination Controls
                HStack {
                    Button(action: {
                        if currentPage > 0 {
                            currentPage -= 1
                        } else {
                            onNavigateToPreviousPhase?()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentPage <= 0 && onNavigateToPreviousPhase == nil)

                    Spacer()
                    Text("\(currentPage + 1) / \(totalPages)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()

                    Button(action: {
                        if currentPage < totalPages - 1 {
                            currentPage += 1
                        } else {
                            onNavigateToNextPhase?()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentPage >= totalPages - 1 && onNavigateToNextPhase == nil)
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
                .frame(height: 30)
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
        // Convert any #number references to Markdown links
        let processedText = textPage.convertVectorReferencesToDeepLinks()

        Markdown(processedText)
            .markdownTheme(.normalizedHeadings)
            .padding([.horizontal, .top], 4)
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
            pages = [markdownText]
            totalPages = 1
            currentPage = 0
            return
        }

        // Use original text for pagination to avoid issues with HTML elements
        // The vector references will be converted to HTML links when rendering each page

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
            // Calculate new pages with the original text
            // Processing happens in markdownPageView for each individual page
            let newPages = splitMarkdownIntoPages(markdownText, size: size)
            pages = newPages

            // Store the result in cache
            cache = PaginationCache(
                text: markdownText,
                width: size.width,
                height: size.height,
                pages: newPages
            )
        }

        totalPages = max(1, pages.count)

        // Ensure currentPage is within bounds
        if currentPage >= totalPages {
            currentPage = max(0, totalPages - 1)
        } else if currentPage < 0 {
            currentPage = 0
        }
    }

    private func splitMarkdownIntoPages(_ text: String, size: CGSize) -> [String] {
        guard !text.isEmpty else { return [""] }
        guard size.width > 8, size.height > 40 else {
            return [text]
        }

        let measurer = TextMeasurer(sizeCategory: .medium)
        let paginationControlsHeight: CGFloat = 35
        let verticalPadding: CGFloat = 8
        let availableTextHeight = size.height - verticalPadding - paginationControlsHeight

        guard availableTextHeight > 20 else {
            return [text]
        }

        let availableTextWidth = size.width - 8

        var pagesResult: [String] = []
        var remainingText = Substring(text)

        while !remainingText.isEmpty {
            let pageText = measurer.fitTextToHeight(
                text: String(remainingText),
                width: availableTextWidth,
                height: availableTextHeight
            )

            guard !pageText.isEmpty else {
                if !remainingText.isEmpty {
                    pagesResult.append(String(remainingText))
                }
                remainingText = ""
                break
            }

            pagesResult.append(pageText)

            if pageText.count < remainingText.count {
                let index = remainingText.index(remainingText.startIndex, offsetBy: pageText.count)
                remainingText = remainingText[index...]
            } else {
                remainingText = ""
            }
        }

        if pagesResult.isEmpty && !text.isEmpty {
            return [text]
        }
        if pagesResult.isEmpty && text.isEmpty {
            return [""]
        }

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

    private func fetchVectorFromAPI(vectorId: String, message: Message) {
        // First check if we already have this vector in the local results with exact match
        if let localVector = message.vectorSearchResults.first(where: { $0.id == vectorId }) {
            displayVectorResult(localVector, index: -1) // Use -1 to indicate it's not a position-based reference
            return
        }

        // If exact match fails, try partial match for truncated IDs
        if let partialMatchVector = message.vectorSearchResults.first(where: {
            guard let fullId = $0.id else { return false }
            return fullId.hasPrefix(vectorId) || vectorId.hasPrefix(fullId)
        }) {
            displayVectorResult(partialMatchVector, index: -1)
            return
        }

        // Show loading indicator
        let loadingContent = """
        # Loading Vector Content

        Fetching full content for vector ID: \(vectorId)...

        Please wait...
        """
        TextSelectionManager.shared.showSheet(withText: loadingContent)

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

                // If we get a 404, it might be because the vector ID is truncated
                // Try to find a vector with a similar ID in the local results
                if httpResponse.statusCode == 404 {
                    // Try to find a vector with an ID that starts with the provided ID
                    if let partialMatchVector = message.vectorSearchResults.first(where: {
                        guard let fullId = $0.id else { return false }
                        return fullId.hasPrefix(vectorId) || vectorId.hasPrefix(fullId)
                    }) {
                        // Found a match, display it
                        await MainActor.run {
                            displayVectorResult(partialMatchVector, index: -1)
                        }
                        return
                    } else {
                        // No match found, throw an error
                        throw NSError(domain: "Vector not found", code: 404)
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

                // Display the result
                await MainActor.run {
                    displayVectorResult(vectorResult, index: -1) // Use -1 to indicate it's not a position-based reference
                }

            } catch {
                // Show error
                await MainActor.run {
                    let errorContent = """
                    # Error Fetching Vector Content

                    Failed to fetch content for vector ID: \(vectorId)

                    Error: \(error.localizedDescription)
                    """
                    TextSelectionManager.shared.showSheet(withText: errorContent)
                }
            }
        }
    }

    private func displayVectorResult(_ vectorResult: VectorSearchResult, index: Int) {
        // Format initial content with metadata
        var formattedContent = """
        # Vector Result
        """

        // Add index if it's a position-based reference
        if index > 0 {
            formattedContent = """
            # Vector Result #\(index)
            """
        }

        formattedContent += """

        Score: \(String(format: "%.2f", vectorResult.score))
        """

        // Add provider if available
        if let provider = vectorResult.provider {
            formattedContent += "\nProvider: \(provider)"
        }

        // Add ID if available
        if let id = vectorResult.id {
            formattedContent += "\nID: \(id)"
        }

        // Add other metadata if available
        if let metadata = vectorResult.metadata, !metadata.isEmpty {
            formattedContent += "\n\nMetadata:"
            for (key, value) in metadata.sorted(by: { $0.key < $1.key }) {
                formattedContent += "\n- \(key): \(value)"
            }
        }

        // Debug info
        formattedContent += "\n\nContent Length: \(vectorResult.content.count) characters"

        // Use best available content version
        let contentToDisplay = vectorResult.content

        formattedContent += """

        ---

        \(contentToDisplay)
        """

        // Show the content in a text selection sheet
        TextSelectionManager.shared.showSheet(withText: formattedContent)
    }
}
