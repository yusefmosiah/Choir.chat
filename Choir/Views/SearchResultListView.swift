import SwiftUI

// Enum to wrap different search result types
enum UnifiedSearchResult: Identifiable, Hashable {
    case vector(VectorSearchResult)
    case web(SearchResult)

    var id: String {
        switch self {
        case .vector(let result): return result.uniqueId
        case .web(let result): return result.id
        }
    }

    // Implement Hashable ourselves
    func hash(into hasher: inout Hasher) {
        switch self {
        case .vector(let result):
            hasher.combine(result)
            hasher.combine(0) // Type discriminator
        case .web(let result):
            hasher.combine(result)
            hasher.combine(1) // Type discriminator
        }
    }

    static func == (lhs: UnifiedSearchResult, rhs: UnifiedSearchResult) -> Bool {
        switch (lhs, rhs) {
        case (.vector(let lhsResult), .vector(let rhsResult)):
            return lhsResult == rhsResult
        case (.web(let lhsResult), .web(let rhsResult)):
            return lhsResult == rhsResult
        default:
            return false
        }
    }
}

struct SearchResultListView: View {
    let title: String
    let icon: String
    let results: [UnifiedSearchResult]
    @Binding var currentPage: Int
    let availableSize: CGSize // Pass available size for pagination calculation
    let localThreadIDs: Set<UUID>

    // Pagination state
    @State private var totalPages: Int = 1
    private let itemsPerPage: Int = 5 // Adjust as needed

    // Navigation Callbacks
    var onNavigateToPreviousPhase: (() -> Void)?
    var onNavigateToNextPhase: (() -> Void)?

    // Environment
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // No spacing for seamless list
             // Header for the list
             HStack {
                 Image(systemName: icon)
                 Text("\(title) (Page \(currentPage + 1) of \(totalPages))")
                     .font(.caption)
                     .foregroundColor(.secondary)
                 Spacer()
             }
             .padding(.bottom, 5)
             .padding(.horizontal, 5) // Add slight horizontal padding

            VStack(alignment: .leading, spacing: 10) {
                ForEach(pagedResults) { result in
                    switch result {
                    case .vector(let vectorResult):
                        VectorResultCard(result: vectorResult, localThreadIDs: localThreadIDs)
                    case .web(let webResult):
                        WebResultCard(result: webResult, openURL: openURL)
                    }
                }
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Pagination Controls (similar to PaginatedTextView)
            PaginationControls(
                currentPage: $currentPage,
                totalPages: $totalPages,
                onNavigateToPreviousPhase: onNavigateToPreviousPhase,
                onNavigateToNextPhase: onNavigateToNextPhase
            )
        }
        .onAppear(perform: calculatePages)
        .onChange(of: results) { _, _ in calculatePages() } // Recalculate on results change
    }

    // Calculate results for the current page
    private var pagedResults: [UnifiedSearchResult] {
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, results.count)
        guard startIndex < endIndex else { return [] }
        return Array(results[startIndex..<endIndex])
    }

    // Calculate total pages
    private func calculatePages() {
        totalPages = max(1, Int(ceil(Double(results.count) / Double(itemsPerPage))))
        // Ensure current page is valid
        if currentPage >= totalPages {
            currentPage = max(0, totalPages - 1)
        }
         print("Calculated pages for \(title): \(totalPages), Current: \(currentPage), Results: \(results.count)")
    }
}

// MARK: - Subviews for Result Cards

struct VectorResultCard: View {
    let result: VectorSearchResult
    let localThreadIDs: Set<UUID>

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let threadIDString = result.metadata?["thread_id"] as? String,
               let threadUUID = UUID(uuidString: threadIDString),
               localThreadIDs.contains(threadUUID) {
                Button(action: {
                    if let url = URL(string: "choir://thread/\(threadIDString)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text(result.content)
                        .font(.body)
                        .lineLimit(4)
                        .foregroundColor(.blue)
                        .underline()
                }
                .buttonStyle(.plain)
            } else {
                Text(result.content)
                    .font(.body)
                    .lineLimit(4)
            }

            HStack {
                Text("Score: \(String(format: "%.2f", result.score))")
                    .font(.caption)
                    .foregroundColor(.orange)
                Spacer()
                Text(result.provider ?? "qdrant")
                     .font(.caption)
                     .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(8)
    }
}

struct WebResultCard: View {
    let result: SearchResult
    let openURL: OpenURLAction // Pass openURL from environment

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(result.title)
                .font(.headline)
                .lineLimit(1)

            Text(result.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if let url = URL(string: result.url) {
                Button {
                    openURL(url)
                } label: {
                    Text(result.url)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading) // Ensure button takes width
                }
                 .buttonStyle(.plain) // Use plain style to avoid default button appearance
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Reusable Pagination Controls

struct PaginationControls: View {
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    var onNavigateToPreviousPhase: (() -> Void)?
    var onNavigateToNextPhase: (() -> Void)?

    var body: some View {
        HStack {
            Button(action: {
                if currentPage > 0 {
                    currentPage -= 1
                } else if let navigateToPrevious = onNavigateToPreviousPhase {
                    navigateToPrevious()
                }
            }) {
                Image(systemName: "chevron.left")
                    .imageScale(.small)
                    .padding(4)
            }
            .disabled(currentPage <= 0 && onNavigateToPreviousPhase == nil)
            .foregroundColor(currentPage <= 0 && onNavigateToPreviousPhase == nil ? .gray : .accentColor)

            Spacer()


            Spacer()

            Button(action: {
                if currentPage < totalPages - 1 {
                    currentPage += 1
                } else if let navigateToNext = onNavigateToNextPhase {
                    navigateToNext()
                }
            }) {
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .padding(4)
            }
            .disabled(currentPage >= totalPages - 1 && onNavigateToNextPhase == nil)
            .foregroundColor(currentPage >= totalPages - 1 && onNavigateToNextPhase == nil ? .gray : .accentColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .cornerRadius(8)
        .padding(.bottom, 2)
        .frame(height: 36)
    }
}

// MARK: - Preview

struct SearchResultListPreview: View {
    @State private var vectorPage = 0
    @State private var webPage = 0

    var body: some View {
        VStack {
            Text("Vector Results Example")
            SearchResultListView(
                title: "Vector Docs",
                icon: "doc.text.magnifyingglass",
                results: [
                    VectorSearchResult(content: "This is vector result 1, showing some relevant internal document content.", score: 0.91, provider: "qdrant", metadata: nil),
                    VectorSearchResult(content: "Vector result 2 provides further context from another source.", score: 0.88, provider: "qdrant", metadata: nil),
                    VectorSearchResult(content: "A third vector result snippet.", score: 0.85, provider: "qdrant", metadata: nil),
                    VectorSearchResult(content: "Fourth snippet.", score: 0.84, provider: "qdrant", metadata: nil),
                    VectorSearchResult(content: "Fifth snippet.", score: 0.83, provider: "qdrant", metadata: nil),
                    VectorSearchResult(content: "Sixth snippet, should be on page 2.", score: 0.82, provider: "qdrant", metadata: nil)
                ].map { .vector($0) },
                currentPage: $vectorPage,
                availableSize: CGSize(width: 300, height: 400),
                localThreadIDs: [],
                onNavigateToPreviousPhase: { print("Navigate Prev Phase (Vector)") },
                onNavigateToNextPhase: { print("Navigate Next Phase (Vector)") }
            )
            .frame(height: 250)
            .border(Color.red) // Add border for layout debugging

            Divider()

            Text("Web Results Example")
            SearchResultListView(
                title: "Web Search",
                icon: "network",
                results: [
                    SearchResult(title: "Web Result A", url: "https://example.com/a", content: "Content snippet from web result A.", provider: "brave_search"),
                    SearchResult(title: "Web Result B", url: "https://example.com/b", content: "Another snippet from the web, this time for B.", provider: "brave_search")
                ].map { .web($0) },
                currentPage: $webPage,
                availableSize: CGSize(width: 300, height: 400),
                localThreadIDs: [],
                onNavigateToPreviousPhase: { print("Navigate Prev Phase (Web)") },
                onNavigateToNextPhase: { print("Navigate Next Phase (Web)") }
            )
            .frame(height: 250)
            .border(Color.blue) // Add border for layout debugging
        }
        .padding()
    }
}

struct SearchResultListView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultListPreview()
    }
}
