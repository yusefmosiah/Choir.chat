import SwiftUI
import Foundation

struct PhasePaginationControlView: View {
    // Input properties
    @ObservedObject var message: Message
    let availablePhases: [Phase]
    let size: CGSize
    
    // Callback for phase switching
    let onSwitchPhase: (SwipeDirection) -> Void
    
    // Pagination direction enum
    enum PageTapDirection { case previous, next }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left tap area
            Color.clear
                .frame(width: max(0, (size.width - (size.width * 0.8)) / 2))
                .padding(.leading, -20) // Expand overlay outward beyond parent bounds
                .contentShape(Rectangle())
                .onTapGesture {
                    print("LEFT TAP AREA TAPPED")
                    handlePageTap(direction: .previous)
                }
            
            Spacer()
            
            // Right tap area
            Color.clear
                .frame(width: max(0, size.width - (size.width * 0.7)))
                .padding(.trailing, -60) // Expand overlay outward beyond parent bounds
                .contentShape(Rectangle())
                .onTapGesture {
                    print("RIGHT TAP AREA TAPPED")
                    handlePageTap(direction: .next)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Functions
    
    private func handlePageTap(direction: PageTapDirection) {
        guard size != .zero else {
            print("Error: Size is zero, cannot calculate pages.")
            return
        }
        
        let phase = message.selectedPhase // Get currently selected phase
        let currentPage = message.phaseCurrentPage[phase] ?? 0
        
        // Get the content and search results for the current phase
        let content = message.getPhaseContent(phase)
        let vectorResults = message.vectorSearchResults.map { UnifiedSearchResult.vector($0) }
        let webResults = message.webSearchResults.map { UnifiedSearchResult.web($0) }
        let searchResults = vectorResults + webResults
        
        // Create a pagination service to calculate total pages
        let paginationService = PaginationService()
        let totalPages = paginationService.calculateTotalPages(
            markdownText: content,
            searchResults: searchResults,
            size: size
        )
        
        print("handlePageTap: Phase=\(phase), CurrentPage=\(currentPage + 1), TotalPages=\(totalPages), Direction=\(direction)") // Debug
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if direction == .previous {
                if currentPage > 0 {
                    message.phaseCurrentPage[phase] = currentPage - 1
                    print("Tapped Left: Now Page \(currentPage)") // Debug
                } else {
                    print("Tapped Left: Switching Phase Previous") // Debug
                    onSwitchPhase(.previous)
                }
            } else { // .next
                if currentPage < totalPages - 1 {
                    message.phaseCurrentPage[phase] = currentPage + 1
                    print("Tapped Right: Now Page \(currentPage + 2)") // Debug
                } else {
                    print("Tapped Right: Switching Phase Next") // Debug
                    onSwitchPhase(.next)
                }
            }
        }
    }
}

// Direction enum for phase switching
enum SwipeDirection { case next, previous }

#Preview {
    // Mock data for preview
    let testMessage = Message(content: "Test message content", isUser: false)
    
    return PhasePaginationControlView(
        message: testMessage,
        availablePhases: Phase.allCases,
        size: CGSize(width: 300, height: 500),
        onSwitchPhase: { _ in }
    )
    .frame(height: 300)
    .padding()
    .background(Color.gray.opacity(0.2))
}