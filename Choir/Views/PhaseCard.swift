import Foundation
import SwiftUI

struct PhaseCard: View {
    let phase: Phase
    @ObservedObject var message: Message
    // Removed thread reference
    let isSelected: Bool
    var isLoading: Bool = false
    // var priors: [Prior]? = nil // REMOVE: Prior struct is removed
    @ObservedObject var viewModel: PostchainViewModel  // Keep viewModel for SearchResultListView
    var messageId: String?  // Message ID parameter
    let localThreadIDs: Set<UUID>

    // --- Computed Properties for Styling ---

    private var cardBackgroundColor: Color {
        phase == .yield ? Color.accentColor : Color(.systemBackground)  // Use semantic color
    }

    private var primaryTextColor: Color {
        phase == .yield ? .white : .primary
    }

    private var secondaryTextColor: Color {
        phase == .yield ? .white.opacity(0.8) : .secondary
    }

    private var headerIconColor: Color {
        phase == .yield ? .white : .accentColor
    }

    private var shadowOpacity: Double {
        isSelected ? 0.2 : 0.1
    }

    private var shadowRadius: CGFloat {
        isSelected ? 8 : 3
    }

    private var shadowYOffset: CGFloat {
        isSelected ? 3 : 1
    }

    private var overlayStrokeColor: Color {
        if isSelected {
            return phase == .yield ? Color.white : Color.accentColor
        } else {
            return Color.gray.opacity(0.2)
        }
    }

    private var overlayLineWidth: CGFloat {
        isSelected ? 2 : 1
    }

    // Binding for current page in the phase
    private var pageBinding: Binding<Int> {
        Binding<Int>(
            get: { message.phaseCurrentPage[phase] ?? 0 },
            set: { message.phaseCurrentPage[phase] = $0 }
        )
    }

    // --- Body ---

    var body: some View {
        // Compute markdown content and displayable flag outside ViewBuilder
        let baseContent = message.getPhaseContent(phase)
        var combinedMarkdown = baseContent
        if phase == .experienceVectors && !message.vectorSearchResults.isEmpty {
            combinedMarkdown += message.formatVectorResultsToMarkdown()
        } else if phase == .experienceWeb && !message.webSearchResults.isEmpty {
            combinedMarkdown += message.formatWebResultsToMarkdown()
        }
        let hasDisplayableContent = !combinedMarkdown.isEmpty

        return VStack(alignment: .leading, spacing: 12) {
            // Header (Keep existing header)

            if hasDisplayableContent {
                GeometryReader { geometry in
                    PaginatedMarkdownView(
                        markdownText: combinedMarkdown,
                        availableSize: geometry.size,
                        currentPage: pageBinding,
                        onNavigateToPreviousPhase: createNavigationHandler(direction: .previous),
                        onNavigateToNextPhase: createNavigationHandler(direction: .next)
                    )
                }
            } else if isLoading {
                loadingContentView
            } else {
                emptyContentView
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
                .shadow(
                    color: Color.black.opacity(shadowOpacity),
                    radius: shadowRadius,
                    x: 0,
                    y: shadowYOffset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: .green, location: 0.0),
                            .init(color: .blue, location: 0.25),
                            .init(color: .purple, location: 0.5),
                            .init(color: .blue, location: 0.75),
                            .init(color: .green, location: 1.0),
                        ]),
                        center: .center
                    ),
                    lineWidth: overlayLineWidth
                )
        )
        .padding(.horizontal, 4)
        .contextMenu {
            PhaseCardContextMenu(
                phase: phase,
                message: message,
                currentPage: pageBinding,
                availableSize: UIScreen.main.bounds.size
            )
        }
    }

    // --- Helper Views for Content Area ---
    private var loadingContentView: some View {
        VStack(spacing: 12) {
            Spacer()
            HStack {
                Spacer()
                ProgressView()
                    .tint(secondaryTextColor)
                Text("Loading...")
                    .foregroundColor(secondaryTextColor)
                Spacer()
            }
            Spacer()
        }
        .padding(.vertical, 20)
    }

    private var emptyContentView: some View {
        Text("No content available")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
    }

    // --- Helper Function for Navigation Callbacks ---
    enum NavigationDirection { case previous, next }

    private func createNavigationHandler(direction: NavigationDirection) -> () -> Void {
        return {
            guard let currentPhaseIndex = Phase.allCases.firstIndex(of: phase) else { return }
            let targetPhaseIndex =
                direction == .previous ? currentPhaseIndex - 1 : currentPhaseIndex + 1

            guard targetPhaseIndex >= 0 && targetPhaseIndex < Phase.allCases.count else { return }

            let targetPhase = Phase.allCases[targetPhaseIndex]
            let targetPage = direction == .previous ? 999 : 0  // Set to max for previous, 0 for next

            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                message.selectedPhase = targetPhase
                message.phaseCurrentPage[targetPhase] = targetPage
            }
        }
    }
}

#Preview {
    // Mock ViewModel and Message for Preview
    let previewViewModel = PostchainViewModel(coordinator: RESTPostchainCoordinator())
    let testMessage = Message(
        content: "Test message content",
        isUser: false
    )

    PhaseCard(
        phase: Phase.action,  // Explicitly use Phase enum
        message: testMessage,
        isSelected: true,
        isLoading: false,
        viewModel: previewViewModel,
        messageId: testMessage.id.uuidString,
        localThreadIDs: []
    )
    .frame(height: 300)
    .padding()
}
