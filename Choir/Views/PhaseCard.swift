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

    // State to track updates
    @State private var cardRefreshCounter = 0

    var body: some View {
        // Compute markdown content and displayable flag outside ViewBuilder
        let baseContent = message.getPhaseContent(phase)
        var combinedMarkdown = baseContent
        if phase == .experienceVectors && !message.vectorSearchResults.isEmpty {
            combinedMarkdown += message.formatVectorResultsToMarkdown()
        } else if phase == .experienceWeb && !message.webSearchResults.isEmpty {
            combinedMarkdown += message.formatWebResultsToMarkdown()
        }
        // Special handling for yield phase - show content even if it's from initial test content
        let hasDisplayableContent = !combinedMarkdown.isEmpty

        // Debug logging for all phases to compare
        print("\n🔍 PHASE CARD DIAGNOSIS - \(phase.rawValue.uppercased()) - START")
        print("🔍 PHASE CARD: Phase: \(phase.rawValue)")
        print("🔍 PHASE CARD: Message ID: \(message.id)")
        print("🔍 PHASE CARD: Base content length: \(baseContent.count)")
        print("🔍 PHASE CARD: Combined markdown length: \(combinedMarkdown.count)")
        print("🔍 PHASE CARD: Has displayable content: \(hasDisplayableContent)")
        print("🔍 PHASE CARD: Is loading: \(isLoading)")

        // Check raw phase result
        let phaseResult = message.getPhaseResult(phase)
        print("🔍 PHASE CARD: Raw phase result: \(phaseResult != nil ? "exists" : "nil")")
        if let result = phaseResult {
            print("🔍 PHASE CARD: Result content length: \(result.content.count)")
            print("🔍 PHASE CARD: Result content empty: \(result.content.isEmpty)")
            print("🔍 PHASE CARD: Result provider: \(result.provider ?? "nil")")
            print("🔍 PHASE CARD: Result model: \(result.modelName ?? "nil")")
            if result.content.isEmpty {
                print("🔍 PHASE CARD WARNING: Result content is empty!")
            } else {
                print("🔍 PHASE CARD: Content first 50 chars: \(result.content.prefix(50))")
            }
        }

        // Minimal yield phase debug info
        if phase == .yield {
            if let rawYieldContent = message.phaseResults[.yield]?.content {
                print("🔍 YIELD: Raw content length: \(rawYieldContent.count)")
            }
        }

        // For debugging comparing the yield phase with other phases that work
        if phase == .yield || phase == .action || phase == .understanding {
            print("🔍 PHASE COMPARISON: Phases in message.phaseResults: \(message.phaseResults.keys.map { $0.rawValue }.joined(separator: ", "))")
            print("🔍 PHASE COMPARISON: Selected phase is: \(message.selectedPhase.rawValue)")

            // Compare with a phase that works (action or understanding)
            let comparePhase = phase == .yield ? .action : phase
            let compareContent = message.phaseResults[comparePhase]?.content ?? ""
            print("🔍 PHASE COMPARISON: \(comparePhase.rawValue) content length: \(compareContent.count)")
            print("🔍 PHASE COMPARISON: \(comparePhase.rawValue) content empty: \(compareContent.isEmpty)")
        }

        print("🔍 PHASE CARD DIAGNOSIS - \(phase.rawValue.uppercased()) - END\n")

        // Force refresh content when message changes
        let _ = cardRefreshCounter

        // Debug output for all phases to see why yield is different
        print("📱 DISPLAY CHECK (\(phase.rawValue)): hasDisplayableContent=\(hasDisplayableContent)")
        print("📱 DISPLAY CHECK (\(phase.rawValue)): isLoading=\(isLoading)")
        print("📱 DISPLAY CHECK (\(phase.rawValue)): content length=\(combinedMarkdown.count)")

        // In case the problem is with the empty check, double-check it manually
        if !combinedMarkdown.isEmpty {
            print("📱 DISPLAY CHECK (\(phase.rawValue)): Content is NOT empty - should display content")
        } else {
            print("📱 DISPLAY CHECK (\(phase.rawValue)): Content IS empty - should show placeholder")
        }

        // DEBUG LOG: Add specific logging for PhaseCard display
        if phase == .yield {
            let displayContent = combinedMarkdown // Use the already computed content
            print("⚪️ PHASECARD (Yield): Displaying content for message ID \(message.id). Content length: \(displayContent.count)")
        }
        return VStack(alignment: .leading, spacing: 12) {
            // Header (Keep existing header)

            if !combinedMarkdown.isEmpty {
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
                // For debugging, identify the phase in "No content available" message
                VStack {
                    Text("No content available for \(phase.rawValue) phase")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)

                    // Add debug info
                    if phase == .yield {
                        Text("Debug info: Check logs for yield phase diagnosis")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.top, 10)
                    }
                }
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
        .onReceive(message.objectWillChange) {
            // Update card when message changes
            cardRefreshCounter += 1
            print("🔄 CARD: Message changed for phase \(phase.rawValue), refreshing view")

            // Check all phases to compare
            for checkPhase in Phase.allCases {
                let checkContent = message.phaseResults[checkPhase]?.content ?? ""
                print("🔄 REFRESH CHECK (\(checkPhase.rawValue)): Content length \(checkContent.count)")
                print("🔄 REFRESH CHECK (\(checkPhase.rawValue)): Content empty \(checkContent.isEmpty)")
            }
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
    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())
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
