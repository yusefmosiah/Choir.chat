import SwiftUI

struct PaginatedTextView: View {
    let text: String
    let availableSize: CGSize
    @Binding var currentPage: Int

    // Add callbacks for phase navigation
    var onNavigateToPreviousPhase: (() -> Void)?
    var onNavigateToNextPhase: (() -> Void)?

    // Internal state
    @State private var pages: [String] = [""]
    @State private var totalPages: Int = 1
    @State private var estimatedCharsPerPage: Int = 500

    var body: some View {
        VStack {
            Text(pages.indices.contains(currentPage) ? pages[currentPage] : "")
                .font(.body)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding([.horizontal, .top], 4)

            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Page controls - reduced vertical padding and made more compact
            HStack {
                Button(action: {
                    if currentPage > 0 {
                        currentPage -= 1
                    } else if let navigateToPrevious = onNavigateToPreviousPhase {
                        // If on first page, navigate to previous phase
                        navigateToPrevious()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.small)
                        .padding(4) // Reduced padding
                }
                // Only disable if on first page AND no previous phase callback
                .disabled(currentPage <= 0 && onNavigateToPreviousPhase == nil)
                .foregroundColor(currentPage <= 0 && onNavigateToPreviousPhase == nil ? .gray : .accentColor)

                Spacer()

                Text("Page \(currentPage + 1) of \(totalPages)")
                    .font(.caption2) // Smaller font
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    if currentPage < totalPages - 1 {
                        currentPage += 1
                    } else if let navigateToNext = onNavigateToNextPhase {
                        // If on last page, navigate to next phase
                        navigateToNext()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .padding(4) // Reduced padding
                }
                // Only disable if on last page AND no next phase callback
                .disabled(currentPage >= totalPages - 1 && onNavigateToNextPhase == nil)
                .foregroundColor(currentPage >= totalPages - 1 && onNavigateToNextPhase == nil ? .gray : .accentColor)
            }
            .padding(.horizontal, 8) // Reduced horizontal padding
            .padding(.vertical, 4) // Reduced vertical padding
            .background(Color(.secondarySystemBackground).opacity(0.6))
            .cornerRadius(8)
            .padding(.bottom, 2) // Reduced bottom padding to position closer to the bottom
            .padding(.top, 4) // Added small top padding to separate from content
        }
        .onAppear {
            recalculatePages()
        }
        .onChange(of: text) { _, _ in
            recalculatePages()
        }
        .onChange(of: availableSize) { _, _ in
            recalculatePages()
        }
    }

    // Recalculate pages based on content and estimated characters per page
    private func recalculatePages() {
        guard !text.isEmpty else {
            pages = [""] // Default to one empty page
            totalPages = 1
            if currentPage != 0 { currentPage = 0 } // Reset page if text cleared
            return
        }

        var resultPages: [String] = []
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            let endIndex = text.index(currentIndex, offsetBy: estimatedCharsPerPage, limitedBy: text.endIndex) ?? text.endIndex
            resultPages.append(String(text[currentIndex..<endIndex]))
            currentIndex = endIndex
        }

        // Update state variables
        let newTotalPages = resultPages.isEmpty ? 1 : resultPages.count
        if totalPages != newTotalPages { totalPages = newTotalPages }
        if pages != resultPages { pages = resultPages.isEmpty ? [""] : resultPages }

        // Ensure currentPage binding remains valid
        if currentPage >= totalPages {
            currentPage = max(0, totalPages - 1)
        }

        print("PaginatedTextView: Recalculated \(totalPages) pages (estimated)")
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var currentPage = 0

        var body: some View {
            PaginatedTextView(
                text: """
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec a diam lectus. Sed sit amet ipsum mauris. Maecenas congue ligula ac quam viverra nec consectetur ante hendrerit. Donec et mollis dolor. Praesent et diam eget libero egestas mattis sit amet vitae augue. Nam tincidunt congue enim, ut porta lorem lacinia consectetur. Donec ut libero sed arcu vehicula ultricies a non tortor. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean ut gravida lorem. Ut turpis felis, pulvinar a semper sed, adipiscing id dolor. Pellentesque auctor nisi id magna consequat sagittis. Curabitur dapibus enim sit amet elit pharetra tincidunt feugiat nisl imperdiet. Ut convallis libero in urna ultrices accumsan. Donec sed odio eros. Donec viverra mi quis quam pulvinar at malesuada arcu rhoncus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. In rutrum accumsan ultricies. Mauris vitae nisi at sem facilisis semper ac in est.

                Vivamus fermentum semper porta. Nunc diam velit, adipiscing ut tristique vitae, sagittis vel odio. Maecenas convallis ullamcorper ultricies. Curabitur ornare, ligula semper consectetur sagittis, nisi diam iaculis velit, id fringilla sem nunc vel mi. Nam dictum, odio nec pretium volutpat, arcu ante placerat erat, non tristique elit urna et turpis. Quisque mi metus, ornare sit amet fermentum et, tincidunt et orci. Fusce eget orci a orci congue vestibulum. Ut dolor diam, elementum et vestibulum eu, porttitor vel elit. Curabitur venenatis pulvinar tellus gravida ornare.
                """,
                availableSize: CGSize(width: 300, height: 400),
                currentPage: $currentPage
            )
            .frame(width: 300, height: 400)
            .border(Color.gray.opacity(0.5), width: 1)
        }
    }

    return PreviewWrapper()
}
