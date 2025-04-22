import SwiftUI

// Define PageDirection enum at file level for reuse
public enum PageDirection { case previous, next }

public struct GlassPageControl: View {
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
            // Previous phase button
            if let previousPhase = getPreviousPhase() {
                Button(action: {
                    onPhaseChange(previousPhase)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption)

                        // Show phase icon if it's action or yield for special carousel effect
                        if previousPhase == .action || previousPhase == .yield {
                            phaseIcon(for: previousPhase)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.1))
                    )
                }
            }

            Spacer()

            // Page controls - only show if there are multiple pages
            if totalPages > 1 {
                Button(action: {
                    onPageChange(.previous)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .opacity(currentPage > 0 ? 1.0 : 0.3)
                }
                .disabled(currentPage <= 0)

                Text("\(currentPage + 1) / \(totalPages)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: {
                    onPageChange(.next)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .opacity(currentPage < totalPages - 1 ? 1.0 : 0.3)
                }
                .disabled(currentPage >= totalPages - 1)
            }

            Spacer()

            // Next phase button
            if let nextPhase = getNextPhase() {
                Button(action: {
                    onPhaseChange(nextPhase)
                }) {
                    HStack(spacing: 4) {
                        // Show phase icon if it's action or yield for special carousel effect
                        if nextPhase == .action || nextPhase == .yield {
                            phaseIcon(for: nextPhase)
                                .font(.caption)
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
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground).opacity(glassOpacity))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
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
