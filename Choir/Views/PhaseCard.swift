import Foundation
import SwiftUI
// Removed UIKit import again

struct PhaseCard: View {
    let phase: Phase
    @ObservedObject var message: Message
    // Removed thread reference
    let isSelected: Bool
    var isLoading: Bool = false
    // var priors: [Prior]? = nil // REMOVE: Prior struct is removed
    @ObservedObject var viewModel: PostchainViewModel
    var messageId: String?
    let localThreadIDs: Set<UUID>
    let pageContent: String // Add property to receive pre-calculated page content

    // --- Computed Properties for Styling ---

    private var cardBackgroundColor: Color {
        Color(.systemBackground)  // Use same background color for all phases
    }

    private var primaryTextColor: Color {
        .primary  // Use same text color for all phases
    }

    private var secondaryTextColor: Color {
        .secondary  // Use same secondary text color for all phases
    }

    private var headerIconColor: Color {
        .accentColor  // Use same icon color for all phases
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
            return Color.accentColor  // Use same stroke color for all phases when selected
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
    @State private var gradientRotation: Double = 0
    @State private var rotationTimer: Timer?

    var body: some View {
        // Use the passed-in pageContent directly
        // Remove calculation of combinedMarkdown

        // Force refresh content when message changes (keep for potential future use)
        let _ = cardRefreshCounter

        VStack(alignment: .leading, spacing: 12) {
            // Header (Keep existing header - assuming it doesn't depend on combinedMarkdown)
            // TODO: Verify Header doesn't need combinedMarkdown

            // Use pageContent to determine if content exists
            if !pageContent.isEmpty {
                // GeometryReader might still be useful if PaginatedMarkdownView needs size constraints internally
                GeometryReader { geometry in
                    // Updated call to PaginatedMarkdownView
                    PaginatedMarkdownView(
                        pageContent: pageContent, // Pass the single page content string
                        // Pass other necessary props like message context or handlers
                        onNavigateToPreviousPhase: createNavigationHandler(direction: .previous),
                        onNavigateToNextPhase: createNavigationHandler(direction: .next),
                        currentMessage: message
                    )
                    // Frame applied to PaginatedMarkdownView itself
                     .frame(width: geometry.size.width, height: geometry.size.height)
                }
            } else if isLoading {
                loadingContentView
            } else {
                // Simplified empty state
                Text("...")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                // Angular gradient shadow (only visible when loading)
                if isLoading {
                    // First create a shape with the angular gradient fill
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .green, location: 0.0),
                                    .init(color: .blue, location: 0.25),
                                    .init(color: .purple, location: 0.5),
                                    .init(color: .blue, location: 0.75),
                                    .init(color: .green, location: 1.0),
                                ]),
                                center: .center,
                                angle: .degrees(gradientRotation)
                            )
                        )
                        // Use relative sizing or remove explicit frame if problematic
                        // .frame(width: UIScreen.main.bounds.width - 32, height: 320) // Removed UIScreen usage
                        // Apply blur for diffuse effect
                        .blur(radius: 12)
                        // Lower opacity for subtlety
                        .opacity(0.5)
                        // Offset slightly to create shadow effect
                        .offset(y: 2)
                }

                // Regular card with standard shadow
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackgroundColor)
                    .shadow(
                        color: Color.black.opacity(shadowOpacity),
                        radius: shadowRadius,
                        x: 0,
                        y: shadowYOffset)
                    // Apply blur for diffuse effect
                    .blur(radius: 6)
                    // Lower opacity for subtlety
                    .opacity(0.5)
            }
        )
        .padding(.horizontal, 4)
        .contextMenu {
            GeometryReader { geometry in
                PhaseCardContextMenu(
                    phase: phase,
                    message: message,
                    currentPage: pageBinding,
                    availableSize: geometry.size
                )
            }
        }
        .onReceive(message.objectWillChange) {
            // Update card when message changes
            cardRefreshCounter += 1

            // Check all phases to compare
            for checkPhase in Phase.allCases {
                let _ = message.phaseResults[checkPhase]?.content ?? ""
            }
        }
        .onAppear {
            // Start rotation timer if loading
            if isLoading {
                startRotationTimer()
            }
        }
        .onChange(of: isLoading) { _, newValue in
            if newValue {
                startRotationTimer()
            } else {
                stopRotationTimer()
            }
        }
        .onDisappear {
            stopRotationTimer()
        }
    }

    // --- Helper Views for Content Area ---
    private var loadingContentView: some View {
        VStack(spacing: 12) {
            Spacer()
            HStack {
                Spacer()
                Text("...")
                    .foregroundColor(secondaryTextColor)
                    .font(.headline)
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

    // --- Rotation Animation Functions ---
    private func startRotationTimer() {
        // Stop any existing timer first
        stopRotationTimer()

        // Reset rotation to 0
        gradientRotation = 0

        // Create a new timer that updates the rotation angle
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [self] _ in
            // Update rotation on the main thread
            DispatchQueue.main.async {
                // Increment rotation by 2 degrees each time
                withAnimation(.linear(duration: 0.02)) {
                    self.gradientRotation = (self.gradientRotation + 2).truncatingRemainder(dividingBy: 360)
                }
            }
        }
    }

    private func stopRotationTimer() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
}

#Preview {
    // Mock ViewModel and Message for Preview
    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())
    let testMessage = Message(content: "Test message content", isUser: false)
    // Add some sample content for preview if needed, or use placeholder
    let samplePageContent = """
    # Sample Page Content

    This is the content for a single page passed to PhaseCard.
    - Item 1
    - Item 2
    """

    VStack(spacing: 20) {
        // Normal state - pass sample pageContent
        PhaseCard(
            phase: Phase.action,
            message: testMessage,
            isSelected: true,
            isLoading: false,
            viewModel: previewViewModel,
            messageId: testMessage.id.uuidString,
            localThreadIDs: [],
            pageContent: samplePageContent // Pass sample content
        )
        .frame(height: 200)

        // Loading state - pass empty pageContent
        PhaseCard(
            phase: Phase.action,
            message: testMessage,
            isSelected: true,
            isLoading: true,
            viewModel: previewViewModel,
            messageId: testMessage.id.uuidString,
            localThreadIDs: [],
            pageContent: "" // Pass empty content for loading state
        )
        .frame(height: 200)
    }
    .padding()
}
