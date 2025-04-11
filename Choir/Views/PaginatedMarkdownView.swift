import SwiftUI
import MarkdownUI

enum PageContent: Identifiable, Hashable {
    case markdown(String)
    case results([UnifiedSearchResult])

    var id: String {
        switch self {
        case .markdown(let text): return "md-\(text.hashValue)"
        case .results(let results): return "res-\(results.hashValue)"
        }
    }
}

struct PaginatedMarkdownView: View {
    let markdownText: String
    let searchResults: [UnifiedSearchResult]
    let availableSize: CGSize
    @Binding var currentPage: Int
    var onNavigateToPreviousPhase: (() -> Void)?
    var onNavigateToNextPhase: (() -> Void)?
    
    // Expose totalPages as a binding for external access
    @Binding var totalPages: Int
    
    // Initialize with default binding if not provided
    init(
        markdownText: String,
        searchResults: [UnifiedSearchResult],
        availableSize: CGSize,
        currentPage: Binding<Int>,
        onNavigateToPreviousPhase: (() -> Void)? = nil,
        onNavigateToNextPhase: (() -> Void)? = nil,
        totalPages: Binding<Int> = .constant(1)
    ) {
        self.markdownText = markdownText
        self.searchResults = searchResults
        self.availableSize = availableSize
        self._currentPage = currentPage
        self.onNavigateToPreviousPhase = onNavigateToPreviousPhase
        self.onNavigateToNextPhase = onNavigateToNextPhase
        self._totalPages = totalPages
    }

    @State private var pages: [PageContent] = []
    @State private var internalTotalPages: Int = 1
    @State private var showingActionSheet = false
    @StateObject private var textSelectionManager = TextSelectionManager.shared

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Color.clear)

                    pageContentView()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .onLongPressGesture {
                    showingActionSheet = true
                }

                Spacer(minLength: 0)
            }
            .onAppear {
                paginateContent(size: geometry.size)
            }
            .onChange(of: markdownText) { _ in paginateContent(size: geometry.size) }
            .onChange(of: searchResults) { _ in paginateContent(size: geometry.size) }
            .onChange(of: geometry.size) { _ in paginateContent(size: geometry.size) }
        }
    }


    @ViewBuilder
    private func pageContentView() -> some View {
        if pages.indices.contains(currentPage) {
            let page = pages[currentPage]
            switch page {
            case .markdown(let textPage):
                markdownPageView(textPage)
            case .results(let results):
                resultsPageView(results)
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
    }

    @ViewBuilder
    private func resultsPageView(_ results: [UnifiedSearchResult]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(results) { result in
                    resultCardView(result)
                }
            }
            .padding(.horizontal, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func resultCardView(_ result: UnifiedSearchResult) -> some View {
        switch result {
        case .vector(let vectorResult):
            VectorResultCard(result: vectorResult, localThreadIDs: [])
        case .web(let webResult):
            WebResultCard(result: webResult)
        }
    }

    private func paginateContent(size: CGSize) {
        // Use PaginationService for consistent pagination logic
        let paginationService = PaginationService()
        let measurer = TextMeasurer(sizeCategory: .medium)
        
        // Get text pages using the service
        let textPages = paginationService.splitMarkdownIntoPages(markdownText, size: size, measurer: measurer)
        
        // Get result pages using the service
        let resultPages = paginationService.chunkResults(searchResults, itemsPerPage: 5)
        
        // Combine pages
        pages = textPages.map { .markdown($0) } + resultPages.map { .results($0) }
        
        // Update both internal and external total pages
        internalTotalPages = pages.count
        totalPages = pages.count
        
        // Ensure current page is valid
        if currentPage >= internalTotalPages {
            currentPage = max(0, internalTotalPages - 1)
        }
    }

    private func splitMarkdownIntoPages(_ text: String, size: CGSize) -> [String] {
        let measurer = TextMeasurer(sizeCategory: .medium)
        let textHeight = size.height - 40
        var pages: [String] = []
        var remainingText = text

        while !remainingText.isEmpty {
            let pageText = measurer.fitTextToHeight(
                text: remainingText,
                width: size.width - 8,
                height: textHeight
            )
            pages.append(pageText)

            if pageText.count < remainingText.count {
                let index = remainingText.index(remainingText.startIndex, offsetBy: pageText.count)
                remainingText = String(remainingText[index...])
            } else {
                remainingText = ""
            }
        }
        return pages
    }

    private func chunkResults(_ results: [UnifiedSearchResult], itemsPerPage: Int) -> [[UnifiedSearchResult]] {
        stride(from: 0, to: results.count, by: itemsPerPage).map {
            Array(results[$0..<min($0 + itemsPerPage, results.count)])
        }
    }

    private func extractCurrentPageText() -> String {
        guard pages.indices.contains(currentPage) else { return "" }
        switch pages[currentPage] {
        case .markdown(let text): return text
        case .results(let results):
            return results.map {
                switch $0 {
                case .vector(let v): return String(v.content.prefix(80))
                case .web(let w): return w.title
                }
            }.joined(separator: "\n")
        }
    }

    private func handleLinkTap(_ url: URL) {
        // Placeholder: show modal preview or navigate
        print("Tapped link: \(url)")
    }
}
