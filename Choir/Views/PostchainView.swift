import SwiftUI

struct PostchainView: View {
    // Unique identifier for this view instance to prevent state sharing
    let viewId: UUID

    // Reference to the specific message this view is displaying
    @ObservedObject var message: Message

    // Processing state
    let isProcessing: Bool

    // Drag state
    @State private var dragOffset: CGFloat = 0

    // Track whether the view has appeared to prevent multiple initializations
    @State private var hasAppeared: Bool = false

    // ViewModel (passed down for ExperienceSourcesView)
    @ObservedObject var viewModel: PostchainViewModel // Added viewModel

    // Computed property to get the selected phase from the message
    private var selectedPhase: Phase {
        get { message.selectedPhase }
        set { message.selectedPhase = newValue }
    }

    // Force showing all phases even when not processing
    var forceShowAllPhases: Bool = false

    // Optional coordinator to check processing status
    var coordinator: RESTPostchainCoordinator?

    // Computed property to get phases directly from the message
    private var phases: [Phase: String] {
        return message.phases
    }

    // Updated initializer to accept viewModel
    init(message: Message, isProcessing: Bool, viewModel: PostchainViewModel, forceShowAllPhases: Bool = false, coordinator: RESTPostchainCoordinator? = nil, viewId: UUID = UUID()) {
        self.message = message
        self.isProcessing = isProcessing
        self.viewModel = viewModel // Initialize viewModel
        self.forceShowAllPhases = forceShowAllPhases
        self.coordinator = coordinator
        self.viewId = viewId

        // Print debug info
        print("PostchainView initialized for message \(message.id) with \(message.phases.count) phases")
    }

    // Computed property to get available phases in order
    private var availablePhases: [Phase] {
        // Force all phases if requested
        if forceShowAllPhases {
            return Phase.allCases
        }

        // Otherwise, get phases that have real content or are being processed
        return Phase.allCases.filter { phase in
            // Has non-empty content
            let hasContent = (phases[phase]?.isEmpty == false)

            // Is currently being processed by the coordinator
            let isProcessing = coordinator?.isProcessingPhase(phase) ?? false

            return hasContent || isProcessing
        }
    }

    var body: some View {
        // Force full content loading on appearance
        let _ = phases

        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.98
            let sideCardWidth = geometry.size.width * 0.1
            let totalWidth = geometry.size.width

            // Simplified to just the carousel without indicators
            ZStack {
                // Only iterate through phases we should actually display
                ForEach(availablePhases) { phase in
                    PhaseCard( // Pass viewModel here
                        phase: phase,
                        content: phases[phase] ?? "",
                        isSelected: phase == selectedPhase,
                        isLoading: (phases[phase]?.isEmpty ?? true) && isProcessing,
                        viewModel: viewModel, // Pass viewModel down
                        messageId: message.id.uuidString // Pass messageId
                    )
                    .frame(width: cardWidth)
                    .offset(x: calculateOffset(for: phase, cardWidth: cardWidth, totalWidth: totalWidth))
                    .zIndex(phase == selectedPhase ? 1 : 0)
                    .opacity(calculateOpacity(for: phase))
                    .id("\(viewId)_\(phase.rawValue)_\(phases[phase]?.count ?? 0)") // Force redraw when content changes, include viewId for uniqueness
                    .onTapGesture {
                        // When a card is tapped, select it
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            message.selectedPhase = phase
                            print("PostchainView: User tapped to select phase: \(phase)")
                        }
                    }
                }
            }
            .frame(height: geometry.size.height * 0.99) // Back to using full height
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.interactiveSpring()) {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        let predictedEndOffset = value.predictedEndTranslation.width
                        let threshold = cardWidth / 3

                        if abs(predictedEndOffset) > threshold {
                            let direction = predictedEndOffset > 0 ? -1 : 1
                            let currentIndex = availablePhases.firstIndex(of: selectedPhase) ?? 0
                            let targetIndex = currentIndex + direction

                            if targetIndex >= 0 && targetIndex < availablePhases.count {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    message.selectedPhase = availablePhases[targetIndex]
                                    dragOffset = 0
                                }
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .padding(.bottom, 16) // Add padding at the bottom of the carousel
        }
        .onAppear {
            // Log available phases on appear for debugging
            print("PostchainView onAppear for message \(message.id): \(availablePhases.count) phases available, hasAppeared: \(hasAppeared)")

            // Set initial phase ONLY if this is the first time the view appears
            if !hasAppeared {
                hasAppeared = true

                // Set initial phase only if we don't have a valid selection yet
                if !availablePhases.contains(message.selectedPhase) && !availablePhases.isEmpty {
                    // Start with yield phase if available (most important), then experience, then action
                    if availablePhases.contains(.yield) {
                        message.selectedPhase = .yield
                        print("PostchainView: Initially selecting yield phase")
                    } else if availablePhases.contains(.experience) {
                        message.selectedPhase = .experience
                        print("PostchainView: Initially selecting experience phase")
                    } else if availablePhases.contains(.action) {
                        message.selectedPhase = .action
                        print("PostchainView: Initially selecting action phase")
                    } else {
                        // Otherwise, select the first available phase
                        message.selectedPhase = availablePhases.first ?? .action
                        print("PostchainView: Initially selecting first available phase: \(message.selectedPhase)")
                    }
                } else {
                    print("PostchainView: Keeping current selection on first appear: \(message.selectedPhase)")
                }
            } else {
                print("PostchainView: View has already appeared, keeping selection: \(message.selectedPhase)")
            }

            // Log available phases
            for phase in availablePhases {
                if let content = phases[phase], !content.isEmpty {
                    print("  - Available: \(phase.rawValue) with content: \(content.prefix(20))...")
                } else {
                    print("  - Available: \(phase.rawValue) (empty)")
                }
            }
        }
        // IMPORTANT: We're NOT using onChange for phases anymore
        // The selection is stored in the message object, so it persists
        // even when the view is recreated
        .id("postchain_view_\(message.id)_\(viewId)") // Stable ID to prevent recreation
    }

    private func calculateOffset(for phase: Phase, cardWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase) else {
            // If no phase is selected yet, use the first available phase
            if let firstPhase = availablePhases.first,
               let firstIndex = availablePhases.firstIndex(of: firstPhase),
               let phaseIndex = availablePhases.firstIndex(of: phase) {
                let indexDifference = phaseIndex - firstIndex
                return CGFloat(indexDifference) * cardWidth + dragOffset
            }
            return totalWidth // Off-screen if not available
        }

        // If the phase is not in available phases but is being processed
        if !availablePhases.contains(phase) && isProcessing {
            if let lastPhase = availablePhases.last,
               let lastIndex = availablePhases.firstIndex(of: lastPhase) {
                // Position it after the last available phase
                let phaseIndex = Phase.allCases.firstIndex(of: phase) ?? 0
                let lastPhaseIndex = Phase.allCases.firstIndex(of: lastPhase) ?? 0

                if phaseIndex > lastPhaseIndex {
                    let indexDifference = (currentIndex - lastIndex) + (phaseIndex - lastPhaseIndex)
                    return CGFloat(indexDifference) * cardWidth + dragOffset
                }
            }
            return totalWidth // Off-screen if not available
        }

        // Normal case - phase is in available phases
        if let phaseIndex = availablePhases.firstIndex(of: phase) {
            let indexDifference = phaseIndex - currentIndex
            return CGFloat(indexDifference) * cardWidth + dragOffset
        }

        return totalWidth // Off-screen if not available
    }

    private func calculateOpacity(for phase: Phase) -> Double {
        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase),
              let phaseIndex = availablePhases.firstIndex(of: phase) else {
            // If phase is being processed but not yet available
            if isProcessing && isNextPhaseToProcess(phase) {
                return 0.5
            }
            return 0
        }

        let indexDifference = abs(phaseIndex - currentIndex)

        if indexDifference == 0 {
            return 1
        } else if indexDifference == 1 {
            return 0.7
        } else {
            return 0.3
        }
    }

    private func isNextPhaseToProcess(_ phase: Phase) -> Bool {
        // If coordinator is available, use it to check
        if let coordinator = coordinator {
            return coordinator.isProcessingPhase(phase)
        }

        // Otherwise, guess based on available phases
        if let lastPhase = availablePhases.last,
           let lastIndex = Phase.allCases.firstIndex(of: lastPhase),
           let phaseIndex = Phase.allCases.firstIndex(of: phase) {
            return phaseIndex == lastIndex + 1
        }

        return false
    }
}

struct PhaseCard: View {
    let phase: Phase
    let content: String?
    let isSelected: Bool
    var isLoading: Bool = false
    var priors: [Prior]? = nil
    @ObservedObject var viewModel: PostchainViewModel
    var messageId: String? // Add messageId parameter

    // --- Computed Properties for Styling ---

    private var cardBackgroundColor: Color {
        phase == .yield ? Color.accentColor : Color(.systemBackground) // Use semantic color
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

    // --- Body ---

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: phase.symbol)
                    .imageScale(.medium)
                    .foregroundColor(headerIconColor)

                Text(phase.rawValue.capitalized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryTextColor)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(secondaryTextColor) // Ensure progress view matches text color
                }
            }
            .padding(.bottom, 4)

            // Content Area
            if let content = content, !content.isEmpty {
                ScrollView {
                    if phase == .experience {
                        // Pass viewModel and messageId to ensure each experience phase has independent state
                        ExperienceSourcesView(viewModel: viewModel, messageId: messageId)
                    } else {
                        Text(content)
                            .font(.body)
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(primaryTextColor)
                    }
                }
                // .frame(minHeight: 300) // Reduced height
            } else if isLoading {
                // Loading State
                VStack(spacing: 12) {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(secondaryTextColor) // Match text color
                        Text("Loading...")
                            .foregroundColor(secondaryTextColor)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                // Empty State
                Text("No content available")
                    .foregroundColor(.secondary) // Use standard secondary for empty state
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(shadowOpacity),
                        radius: shadowRadius,
                        x: 0,
                        y: shadowYOffset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(overlayStrokeColor, lineWidth: overlayLineWidth)
        )
        .padding(.horizontal, 4)
    }
}

struct PriorCard: View {
    let prior: Prior

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Prior ID: \(prior.id)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Similarity: \(Int(prior.similarity * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(prior.content)
                .font(.body)
                .lineLimit(3)

            HStack {
                if let threadID = prior.threadID {
                    Text("Thread: \(threadID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let step = prior.step {
                    Text("Phase: \(step)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let createdAt = prior.createdAt {
                    Text("Created: \(formattedDate(createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground)) // Use semantic color
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        return dateString
    }
}

#Preview {
    // Mock ViewModel for Preview
    let previewViewModel = PostchainViewModel(coordinator: RESTPostchainCoordinator())
    // Add mock data to previewViewModel if needed for ExperienceSourcesView
    // previewViewModel.vectorSources = ["Mock Vector Source"]
    // previewViewModel.webSearchSources = ["https://mock.web.source"]

    let testMessage = Message(
        content: "Test message content",
        isUser: false,
        phases: [
            .action: "I understand you said...",
            .experience: "Based on my experience...", // Content for experience phase
            .intention: "Your intention seems to be...",
            .yield: "Here's my response..."
        ]
    )

    return PostchainView(
        message: testMessage,
        isProcessing: true,
        viewModel: previewViewModel, // Pass the mock viewModel
        forceShowAllPhases: true,
        viewId: UUID()
    )
    .frame(height: 400) // Reduced height
    .padding()
}
