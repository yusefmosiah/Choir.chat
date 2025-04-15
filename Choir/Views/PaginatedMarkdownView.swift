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
                    print("🔗 LINKS: Handling vector deep link: \(url)")
                    handleVectorDeepLink(vectorId: vectorId)
                } else {
                    print("🔗 LINKS: Empty vector ID in deep link: \(url)")
                }
            case "thread":
                // Handle thread links (already implemented elsewhere)
                print("🔗 LINKS: Thread deep link tapped: \(url)")
                break
            default:
                print("🔗 LINKS: Unknown choir:// host: \(host)")
                break
            }
        } else {
            // Open external URLs in Safari
            print("🔗 LINKS: Opening external URL: \(url)")
            UIApplication.shared.open(url)
        }
    }
    
    private func handleVectorDeepLink(vectorId: String) {
        guard let indexNumber = Int(vectorId) else {
            print("🔗 LINKS: Error: Vector ID must be a number, got: \(vectorId)")
            return
        }
        
        // Use the message passed to this view
        guard let message = currentMessage else {
            print("🔗 LINKS: Error: No current message available")
            TextSelectionManager.shared.showSheet(withText: "Unable to display vector result #\(indexNumber): No message context available.")
            return
        }
        
        // Enhanced debug logging to diagnose the issue
        print("🔍 VECTOR LINK: Processing vector link #\(indexNumber)")
        print("🔍 VECTOR LINK: Message ID: \(message.id)")
        print("🔍 VECTOR LINK: Current phase: \(message.selectedPhase.rawValue)")
        print("🔍 VECTOR LINK: Vector results count: \(message.vectorSearchResults.count)")
        
        // Log some details about the vector results if we have any
        if !message.vectorSearchResults.isEmpty {
            print("🔍 VECTOR LINK: First vector content length: \(message.vectorSearchResults[0].content.count)")
            print("🔍 VECTOR LINK: First vector content preview: \(message.vectorSearchResults[0].content.prefix(50))...")
            if let preview = message.vectorSearchResults[0].content_preview {
                print("🔍 VECTOR LINK: First vector has content_preview of length: \(preview.count)")
            }
        }
        
        // IMPORTANT: The vector results are only generated during the experienceVectors phase
        // but references might be in any phase. We need to check if this message is the experienceVectors
        // phase, or if not, we need to find the experienceVectors phase for this thread.
        
        var vectorResults = message.vectorSearchResults
        
        // Option 1: Current message has vector results
        if !vectorResults.isEmpty {
            print("🔍 VECTOR LINK: Current message has \(vectorResults.count) vector results")
            
            if indexNumber > 0 && indexNumber <= vectorResults.count {
                let vectorResult = vectorResults[indexNumber - 1]
                print("🔍 VECTOR LINK: Found vector #\(indexNumber) with content length: \(vectorResult.content.count)")
                print("🔍 VECTOR LINK: Vector #\(indexNumber) preview: \(vectorResult.content.prefix(50))...")
                displayVectorResult(vectorResult, index: indexNumber)
                return
            } else {
                print("🔍 VECTOR LINK: Vector #\(indexNumber) is out of range (1-\(vectorResults.count))")
            }
        } 
        // Option 2: We need to look in the experience_vectors phase specifically
        else if message.selectedPhase != .experienceVectors {
            print("🔍 VECTOR LINK: Current phase is not experienceVectors, looking for vector results in experienceVectors phase")
            
            // Look for vector results in the message's associated experienceVectors phase
            if let expVectorsPhaseResult = message.getPhaseResult(.experienceVectors) {
                print("🔍 VECTOR LINK: Found experienceVectors phase result")
                
                // We have the experience_vectors phase content
                // But we still need to access the vector results stored with this message
                if !message.vectorSearchResults.isEmpty {
                    print("🔍 VECTOR LINK: Found \(message.vectorSearchResults.count) vector results in message")
                    vectorResults = message.vectorSearchResults
                    
                    if indexNumber > 0 && indexNumber <= vectorResults.count {
                        let vectorResult = vectorResults[indexNumber - 1]
                        print("🔍 VECTOR LINK: Found vector #\(indexNumber) with content length: \(vectorResult.content.count)")
                        displayVectorResult(vectorResult, index: indexNumber)
                        return
                    } else {
                        print("🔍 VECTOR LINK: Vector #\(indexNumber) is out of range (1-\(vectorResults.count))")
                    }
                } else {
                    print("🔍 VECTOR LINK: No vector results found in experience phase")
                }
            } else {
                print("🔍 VECTOR LINK: Could not find experienceVectors phase result")
            }
        } else {
            print("🔍 VECTOR LINK: Current phase is experienceVectors but no vector results found")
        }
        
        // If we get here, we couldn't find the vector result in the current message
        print("🔗 LINKS: Could not find vector result #\(indexNumber) in message")
        
        // Create a diagnostic/instructional message
        let diagnosticContent = """
        # Vector Reference Not Found
        
        The reference **#\(indexNumber)** could not be displayed because the vector data isn't available in this view.
        
        ## Why this happens
        Vector references are created during the Experience Vectors phase, but may be referenced in any phase. Sometimes the vector data isn't properly passed between phases.
        
        ## What to try
        1. **Switch to the Experience Vectors phase** by clicking the "Finding Docs" tab - vector references are more reliable there
        2. If that doesn't work, try running your query again with simpler wording
        
        ## Technical Details
        - Message ID: \(message.id)
        - Current phase: \(message.selectedPhase.rawValue)
        - Vector results available: \(vectorResults.count)
        """
        
        // Show the diagnostic content
        TextSelectionManager.shared.showSheet(withText: diagnosticContent)
    }
    
    private func displayVectorResult(_ vectorResult: VectorSearchResult, index: Int) {
        // Debug the vector content
        print("🔍 VECTOR DISPLAY: Showing vector #\(index)")
        print("🔍 VECTOR DISPLAY: Content length: \(vectorResult.content.count)")
        print("🔍 VECTOR DISPLAY: Content preview: \(vectorResult.content.prefix(50))...")
        print("🔍 VECTOR DISPLAY: Content preview available: \(vectorResult.content_preview != nil)")
        if let preview = vectorResult.content_preview {
            print("🔍 VECTOR DISPLAY: Preview length: \(preview.count)")
        }
        
        // Check if vector has an ID and might have fuller content available
        print("🔍 VECTOR DISPLAY: Has ID: \(vectorResult.id != nil)")
        
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
        print("🔗 LINKS: Showing vector result #\(index) with score \(vectorResult.score)")
        TextSelectionManager.shared.showSheet(withText: formattedContent)
    }
}
