import SwiftUI

// Define PageDirection enum at file level for reuse
public enum PageDirection { case previous, next }

public struct GlassPageControl: View {
    // Animation state
    @State private var gradientRotation: Double = 0
    @State private var rotationTimer: Timer?
    @State private var isChangingPhase: Bool = false
    // Current phase and available phases
    let currentPhase: Phase
    let availablePhases: [Phase]

    // Current page and total pages for pagination
    @Binding var currentPage: Int
    let totalPages: Int

    // Callbacks for phase and page changes
    let onPhaseChange: (Phase) -> Void
    let onPageChange: (PageDirection) -> Void

    // Visual properties
    private let glassOpacity: Double = 0.7
    private let glassBlur: CGFloat = 5

    public var body: some View {
        // Glass background with controls
        HStack(spacing: 16) {
            // Left control - handles previous page or previous phase
            Button(action: {
                // If we're on the first page and we can go to a previous phase
                if currentPage == 0 {
                    if let previousPhase = getPreviousPhase() {
                        // Special case for action -> yield carousel
                        let isCarouselTransition = currentPhase == .action && previousPhase == .yield

                        // Show animation for phase change
                        withAnimation {
                            isChangingPhase = true
                        }

                        // Shorter delay for faster animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // For carousel transitions, go to the last page of the previous phase
                            if isCarouselTransition {
                                onPhaseChange(previousPhase)
                            } else {
                                onPhaseChange(previousPhase)
                            }

                            // Hide animation after a shorter delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    isChangingPhase = false
                                }
                            }
                        }
                    }
                } else {
                    // Just go to the previous page
                    onPageChange(.previous)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption)

                    // Show phase icon if we're on first page and going to previous phase
                    if currentPage == 0, let previousPhase = getPreviousPhase() {
                        if previousPhase == .action || previousPhase == .yield {
                            phaseIcon(for: previousPhase)
                                .font(.caption)
                        }
                    }
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.1))
                )
                .opacity((currentPage > 0 || getPreviousPhase() != nil) ? 1.0 : 0.3)
            }
            .disabled(currentPage <= 0 && getPreviousPhase() == nil)

            Spacer()

            // Page indicator - only show if there are multiple pages
            if totalPages > 1 {
                Text("\(currentPage + 1) / \(totalPages)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Right control - handles next page or next phase
            Button(action: {
                // If we're on the last page and we can go to a next phase
                if currentPage >= totalPages - 1 {
                    if let nextPhase = getNextPhase() {
                        // Special case for yield -> action carousel
                        let isCarouselTransition = currentPhase == .yield && nextPhase == .action

                        // Show animation for phase change
                        withAnimation {
                            isChangingPhase = true
                        }

                        // Shorter delay for faster animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // For carousel transitions, go to the first page of the next phase
                            if isCarouselTransition {
                                onPhaseChange(nextPhase)
                            } else {
                                onPhaseChange(nextPhase)
                            }

                            // Hide animation after a shorter delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    isChangingPhase = false
                                }
                            }
                        }
                    }
                } else {
                    // Just go to the next page
                    onPageChange(.next)
                }
            }) {
                HStack(spacing: 4) {
                    // Show phase icon if we're on last page and going to next phase
                    if currentPage >= totalPages - 1, let nextPhase = getNextPhase() {
                        if nextPhase == .action || nextPhase == .yield {
                            phaseIcon(for: nextPhase)
                                .font(.caption)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.1))
                )
                .opacity((currentPage < totalPages - 1 || getNextPhase() != nil) ? 1.0 : 0.3)
            }
            .disabled(currentPage >= totalPages - 1 && getNextPhase() == nil)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            ZStack {
                // Angular gradient shadow - only visible when changing phase
                if isChangingPhase {
                    RoundedRectangle(cornerRadius: 20)
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
                        // Make it slightly larger than the control
                        .frame(width: UIScreen.main.bounds.width - 20, height: 60)
                        // Apply less blur for a sharper, faster-looking effect
                        .blur(radius: 8)
                        // Higher opacity for more vibrant appearance
                        .opacity(0.6)
                }

                // Glass background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground).opacity(glassOpacity))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        )
        .padding(.horizontal, 20)
        .onAppear {
            startRotationTimer()
        }
        .onDisappear {
            stopRotationTimer()
        }
    }

    // Helper function to get the previous phase
    private func getPreviousPhase() -> Phase? {
        // Special case for carousel effect between action and yield
        if currentPhase == .action && availablePhases.contains(.yield) {
            return .yield
        }

        // Standard previous phase
        guard let currentIndex = availablePhases.firstIndex(of: currentPhase),
              currentIndex > 0 else {
            return nil
        }

        return availablePhases[currentIndex - 1]
    }

    // Helper function to get the next phase
    private func getNextPhase() -> Phase? {
        // Special case for carousel effect between action and yield
        if currentPhase == .yield && availablePhases.contains(.action) {
            return .action
        }

        // Standard next phase
        guard let currentIndex = availablePhases.firstIndex(of: currentPhase),
              currentIndex < availablePhases.count - 1 else {
            return nil
        }

        return availablePhases[currentIndex + 1]
    }

    // Helper function to get an icon for a phase
    @ViewBuilder
    private func phaseIcon(for phase: Phase) -> some View {
        switch phase {
        case .action:
            Image(systemName: "play.fill")
        case .experienceVectors:
            Image(systemName: "magnifyingglass")
        case .experienceWeb:
            Image(systemName: "globe")
        case .yield:
            Image(systemName: "checkmark.circle")
        @unknown default:
            Image(systemName: "questionmark.circle")
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
                // Increment rotation by 3 degrees each time for faster animation
                withAnimation(.linear(duration: 0.02)) {
                    self.gradientRotation = (self.gradientRotation + 3).truncatingRemainder(dividingBy: 360)
                }
            }
        }
    }

    private func stopRotationTimer() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
}

// Preview
struct GlassPageControl_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3).edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                GlassPageControl(
                    currentPhase: .action,
                    availablePhases: [.action, .experienceVectors, .yield],
                    currentPage: .constant(1),
                    totalPages: 3,
                    onPhaseChange: { _ in },
                    onPageChange: { _ in }
                )
                .padding(.bottom, 20)
            }
        }
    }
}
