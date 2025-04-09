import SwiftUI

enum PageContent: Identifiable {
    case text(String)
    case results([UnifiedSearchResult])

    var id: String {
        switch self {
        case .text(let content): return "text-\(content.hashValue)"
        case .results(let results): return "results-\(results.hashValue)"
        }
    }
}

struct UnifiedPaginatedView: View {
    let textContent: String
    let searchResults: [UnifiedSearchResult]
    let localThreadIDs: Set<UUID>
    @Binding var currentPage: Int
    let availableSize: CGSize
    var onNavigateToPreviousPhase: (() -> Void)?
    var onNavigateToNextPhase: (() -> Void)?

    @State private var allPages: [PageContent] = []
    @State private var totalPages: Int = 1
    private let itemsPerPage: Int = 5

    var body: some View {
        VStack(spacing: 0) {
            if !allPages.isEmpty && currentPage < allPages.count {
                switch allPages[currentPage] {
                case .text(let textPage):
                    Text(textPage)
                        .font(.body)
                        .lineSpacing(4)
                        .padding([.horizontal, .top], 4)
                        .frame(maxWidth: .infinity,
                               maxHeight: .infinity,
                               alignment: .topLeading)

                case .results(let results):
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(results) { result in
                            switch result {
                            case .vector(let vectorResult):
                                VectorResultCard(result: vectorResult, localThreadIDs: localThreadIDs)
                            case .web(let webResult):
                                WebResultCard(result: webResult,
                                            openURL: OpenURLAction { _ in .systemAction })
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                    .frame(maxHeight: .infinity)
                }
            }

            Spacer(minLength: 0)

            PaginationControls(
                currentPage: $currentPage,
                totalPages: $totalPages,
                onNavigateToPreviousPhase: onNavigateToPreviousPhase,
                onNavigateToNextPhase: onNavigateToNextPhase
            )
        }
        .frame(maxHeight: .infinity)
        .onAppear(perform: calculateAllPages)
        .onChange(of: textContent) { _ in calculateAllPages() }
        .onChange(of: searchResults) { _ in calculateAllPages() }
    }

    private func calculateAllPages() {
        // Calculate text pages
        let textPages = splitTextIntoPages(textContent, size: availableSize)

        // Calculate result pages
        let resultPages = stride(from: 0, to: searchResults.count, by: itemsPerPage).map {
            Array(searchResults[$0..<min($0 + itemsPerPage, searchResults.count)])
        }

        // Combine sequences
        allPages = textPages.map { PageContent.text($0) } +
                   resultPages.map { PageContent.results($0) }
        totalPages = allPages.count

        // Ensure current page is valid
        if currentPage >= totalPages {
            currentPage = max(0, totalPages - 1)
        }
    }

    private func splitTextIntoPages(_ text: String, size: CGSize) -> [String] {
        let measurer = TextMeasurer(sizeCategory: .medium) // Reuse from PaginatedTextView
        let textHeight = size.height - 40 // Account for controls
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
                let index = remainingText.index(
                    remainingText.startIndex,
                    offsetBy: pageText.count
                )
                remainingText = String(remainingText[index...])
            } else {
                remainingText = ""
            }
        }

        return pages
    }
}
