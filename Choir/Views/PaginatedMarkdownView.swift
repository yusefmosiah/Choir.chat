import SwiftUI
import MarkdownUI

struct PaginatedMarkdownView: View {
    let markdownText: String
    let availableSize: CGSize
    @Binding var currentPage: Int
    var onNavigateToPreviousPhase: (() -> Void)?
    var onNavigateToNextPhase: (() -> Void)?

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
        Markdown(textPage)
            .markdownTheme(.normalizedHeadings)
            .onOpenURL { url in
                handleLinkTap(url)
            }
            .padding([.horizontal, .top], 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // Add drawing group to leverage Metal rendering
            .drawingGroup(opaque: false)
    }

    private func paginateContent(size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            pages = [markdownText]
            totalPages = 1
            currentPage = 0
            return
        }
        
        // Check if we have a valid cache that matches current parameters
        let potentialCache = PaginationCache(
            text: markdownText,
            width: size.width,
            height: size.height,
            pages: []
        )
        
        if let existingCache = cache, existingCache == potentialCache {
            // Use cached pages
            pages = existingCache.pages
        } else {
            // Calculate new pages
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
        // Removed print statement to improve performance
    }
}
