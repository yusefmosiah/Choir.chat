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
        guard let indexNumber = Int(vectorId) else {
            TextSelectionManager.shared.showSheet(withText: "Invalid vector reference format. Expected #<number> but got #\(vectorId).")
            return
        }

        // Use the message passed to this view
        guard let message = currentMessage else {
            TextSelectionManager.shared.showSheet(withText: "Unable to display vector result #\(indexNumber): No message context available.")
            return
        }

        // Enhanced debug logging

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
                return resultId.contains(vectorId) || resultId.contains("#\(indexNumber)")
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

    private func displayVectorResult(_ vectorResult: VectorSearchResult, index: Int) {
        // Debug the vector content
        if let preview = vectorResult.content_preview {
        }

        // Check if vector has an ID and might have fuller content available

        // Format initial content with metadata
        var formattedContent = """
        # Vector Result #\(index)

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
        var contentToDisplay = vectorResult.content

        // If content is short and we have an ID, add a note that this might be truncated
        if vectorResult.id != nil && contentToDisplay.count < 500 {
            formattedContent += "\n\n*Note: This is a truncated view. Full content may be available from the server using the vector ID.*"
        }

        formattedContent += """

        ---

        \(contentToDisplay)
        """

        // Show the content in a text selection sheet
        TextSelectionManager.shared.showSheet(withText: formattedContent)
    }
}
