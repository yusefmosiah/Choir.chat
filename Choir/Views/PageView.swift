import SwiftUI

struct PageView: View {
    let content: String
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    var textColor: Color = .primary
    
    // Constants for page layout
    private let wordsPerPage = 150
    private let pageTransition = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )
    
    // Split content into pages
    private var pages: [String] {
        let words = content.split(separator: " ").map(String.init)
        var result: [String] = []
        var currentPageWords: [String] = []
        
        for word in words {
            currentPageWords.append(word)
            
            if currentPageWords.count >= wordsPerPage {
                result.append(currentPageWords.joined(separator: " "))
                currentPageWords = []
            }
        }
        
        // Add the last page if there are remaining words
        if !currentPageWords.isEmpty {
            result.append(currentPageWords.joined(separator: " "))
        }
        
        // If content is empty, add an empty page
        if result.isEmpty {
            result = [""]
        }
        
        // Update total pages
        DispatchQueue.main.async {
            if self.totalPages != result.count {
                self.totalPages = result.count
            }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            // Show the current page
            if !pages.isEmpty && currentPage < pages.count {
                Text(pages[currentPage])
                    .font(.body)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(textColor)
                    .id("page_\(currentPage)") // Force view recreation when page changes
                    .transition(pageTransition)
            } else {
                Text("No content available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
        .onAppear {
            // Update total pages when the view appears
            if totalPages != pages.count {
                totalPages = pages.count
            }
            
            // Ensure current page is valid
            if currentPage >= pages.count && pages.count > 0 {
                currentPage = pages.count - 1
            }
        }
    }
}

#Preview {
    struct PageViewPreview: View {
        @State private var currentPage = 0
        @State private var totalPages = 1
        
        var body: some View {
            VStack {
                PageView(
                    content: "This is a sample text for the page view. It demonstrates how the content is split into multiple pages based on the number of words. This is page 1 of the content. Let's add more text to see how it handles pagination. The page view should automatically split this text into multiple pages and allow navigation between them using the arrow buttons below the content area. This is the end of page 1. Now let's add even more text to create page 2. This text should appear on the second page when the user navigates to it. The transition between pages should be smooth and pleasant. This is the end of page 2. Let's add more text for page 3. This text should appear on the third page. The page view should handle an arbitrary number of pages based on the content length.",
                    currentPage: $currentPage,
                    totalPages: $totalPages
                )
                .frame(height: 300)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 5)
                
                HStack {
                    Button(action: {
                        if currentPage > 0 {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .padding()
                            .background(Circle().fill(Color.blue.opacity(0.1)))
                    }
                    .disabled(currentPage == 0)
                    
                    Text("\(currentPage + 1) / \(totalPages)")
                        .padding(.horizontal)
                    
                    Button(action: {
                        if currentPage < totalPages - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .padding()
                            .background(Circle().fill(Color.blue.opacity(0.1)))
                    }
                    .disabled(currentPage == totalPages - 1)
                }
                .padding()
            }
        }
    }
    
    return PageViewPreview()
}