import SwiftUI
import Combine

/// Manages automatic page progression within conversation turns
/// Monitors content loading state and advances pages when content is ready
class TurnAutoAdvanceManager: ObservableObject {
    @Published var currentPageIndex: Int = 0
    @Published var isAutoAdvanceEnabled: Bool = true
    @Published var hasUserNavigatedManually: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var lastAutoAdvanceIndex: Int = 0
    private var contentMonitorTimer: Timer?

    // Configuration
    private let autoAdvanceDelay: TimeInterval = 1.0 // Delay before auto-advancing
    private let contentCheckInterval: TimeInterval = 0.5 // How often to check for new content

    init() {
        setupContentMonitoring()
    }

    deinit {
        stopContentMonitoring()
    }

    // MARK: - Public Interface

    /// Start monitoring for auto-advance opportunities
    @MainActor
    func startMonitoring(for aiMessage: Message, viewModel: PostchainViewModel) {
        stopContentMonitoring()

        // Monitor changes in AI message content
        aiMessage.objectWillChange
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkForAutoAdvance(aiMessage: aiMessage, viewModel: viewModel)
                }
            }
            .store(in: &cancellables)

        // Monitor changes in processing status
        viewModel.$processingStatus
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkForAutoAdvance(aiMessage: aiMessage, viewModel: viewModel)
                }
            }
            .store(in: &cancellables)

        // Start periodic content checking
        startPeriodicContentCheck(aiMessage: aiMessage, viewModel: viewModel)
    }

    /// Stop all monitoring
    func stopMonitoring() {
        stopContentMonitoring()
        cancellables.removeAll()
    }

    /// Mark that user has manually navigated (temporarily disables auto-advance)
    func markManualNavigation() {
        hasUserNavigatedManually = true
        isAutoAdvanceEnabled = false

        // Re-enable auto-advance after a delay to allow for new content
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.enableAutoAdvanceForNewContent()
        }
    }

    /// Reset auto-advance behavior
    func resetAutoAdvance() {
        hasUserNavigatedManually = false
        isAutoAdvanceEnabled = true
        lastAutoAdvanceIndex = currentPageIndex
    }

    /// Re-enable auto-advance for new content (after manual navigation cooldown)
    private func enableAutoAdvanceForNewContent() {
        // Only re-enable if we're not currently at the latest available content
        isAutoAdvanceEnabled = true
        hasUserNavigatedManually = false
    }

    /// Force check for auto-advance opportunity
    @MainActor
    func checkForAutoAdvance(aiMessage: Message, viewModel: PostchainViewModel) {
        guard isAutoAdvanceEnabled else { return }

        let nextAvailableIndex = findNextAvailablePageIndex(aiMessage: aiMessage, viewModel: viewModel)

        // Only auto-advance if:
        // 1. There's new content available beyond current page
        // 2. We haven't already auto-advanced to this index
        // 3. User hasn't manually navigated recently OR there's significantly new content
        let shouldAutoAdvance = nextAvailableIndex > currentPageIndex &&
                               nextAvailableIndex != lastAutoAdvanceIndex &&
                               (!hasUserNavigatedManually || nextAvailableIndex > lastAutoAdvanceIndex + 1)

        if shouldAutoAdvance {
            // Schedule auto-advance with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + autoAdvanceDelay) { [weak self] in
                Task { @MainActor in
                    self?.performAutoAdvance(to: nextAvailableIndex)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func setupContentMonitoring() {
        // Monitor changes to current page index
        $currentPageIndex
            .sink { [weak self] newIndex in
                // Check if this was a manual navigation
                if let self = self, newIndex != self.lastAutoAdvanceIndex {
                    self.markManualNavigation()
                }
            }
            .store(in: &cancellables)
    }

    private func startPeriodicContentCheck(aiMessage: Message, viewModel: PostchainViewModel) {
        contentMonitorTimer = Timer.scheduledTimer(withTimeInterval: contentCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForAutoAdvance(aiMessage: aiMessage, viewModel: viewModel)
            }
        }
    }

    private func stopContentMonitoring() {
        contentMonitorTimer?.invalidate()
        contentMonitorTimer = nil
    }

    private func performAutoAdvance(to index: Int) {
        guard isAutoAdvanceEnabled && !hasUserNavigatedManually else { return }

        withAnimation(.easeInOut(duration: 0.6)) {
            currentPageIndex = index
            lastAutoAdvanceIndex = index
        }

        // Trigger haptic feedback for auto-advance
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    @MainActor
    private func findNextAvailablePageIndex(aiMessage: Message, viewModel: PostchainViewModel) -> Int {
        // Page indices: 0=User, 1=Action, 2=Experience, 3=IOU, 4=Yield
        var availableIndex = 0 // Always start with user message

        // Check Action phase (index 1)
        if hasContent(for: .action, in: aiMessage) || isStreaming(for: .action, in: aiMessage, viewModel: viewModel) {
            availableIndex = max(availableIndex, 1)
        }

        // Check Experience phase (index 2)
        if hasExperienceContent(in: aiMessage) || isStreamingExperience(in: aiMessage, viewModel: viewModel) {
            availableIndex = max(availableIndex, 2)
        }

        // Check IOU phase (index 3)
        if hasIOUContent(in: aiMessage) || isStreamingIOU(in: aiMessage, viewModel: viewModel) {
            availableIndex = max(availableIndex, 3)
        }

        // Check Yield phase (index 4)
        if hasContent(for: .yield, in: aiMessage) || isStreaming(for: .yield, in: aiMessage, viewModel: viewModel) {
            availableIndex = max(availableIndex, 4)
        }

        return availableIndex
    }

    // MARK: - Content Checking Helpers

    private func hasContent(for phase: Phase, in message: Message) -> Bool {
        return !message.getPhaseContent(phase).isEmpty
    }

    @MainActor
    private func isStreaming(for phase: Phase, in message: Message, viewModel: PostchainViewModel) -> Bool {
        return message.isStreaming && viewModel.processingPhases.contains(phase)
    }

    private func hasExperienceContent(in message: Message) -> Bool {
        return !message.getPhaseContent(.experienceVectors).isEmpty ||
               !message.getPhaseContent(.experienceWeb).isEmpty
    }

    @MainActor
    private func isStreamingExperience(in message: Message, viewModel: PostchainViewModel) -> Bool {
        return message.isStreaming && (
            viewModel.processingPhases.contains(.experienceVectors) ||
            viewModel.processingPhases.contains(.experienceWeb)
        )
    }

    private func hasIOUContent(in message: Message) -> Bool {
        return !message.getPhaseContent(.intention).isEmpty ||
               !message.getPhaseContent(.observation).isEmpty ||
               !message.getPhaseContent(.understanding).isEmpty
    }

    @MainActor
    private func isStreamingIOU(in message: Message, viewModel: PostchainViewModel) -> Bool {
        return message.isStreaming && (
            viewModel.processingPhases.contains(.intention) ||
            viewModel.processingPhases.contains(.observation) ||
            viewModel.processingPhases.contains(.understanding)
        )
    }
}

// MARK: - SwiftUI Integration

/// View modifier to integrate auto-advance manager with a view
struct AutoAdvanceModifier: ViewModifier {
    let aiMessage: Message
    let viewModel: PostchainViewModel
    @StateObject private var autoAdvanceManager = TurnAutoAdvanceManager()
    @Binding var currentPageIndex: Int

    func body(content: Content) -> some View {
        content
            .onAppear {
                autoAdvanceManager.currentPageIndex = currentPageIndex
                autoAdvanceManager.startMonitoring(for: aiMessage, viewModel: viewModel)
            }
            .onDisappear {
                autoAdvanceManager.stopMonitoring()
            }
            .onChange(of: autoAdvanceManager.currentPageIndex) { _, newIndex in
                currentPageIndex = newIndex
            }
            .onChange(of: currentPageIndex) { _, newIndex in
                if newIndex != autoAdvanceManager.currentPageIndex {
                    autoAdvanceManager.markManualNavigation()
                    autoAdvanceManager.currentPageIndex = newIndex
                }
            }
    }
}

extension View {
    /// Add auto-advance behavior to a view
    func autoAdvance(for aiMessage: Message, viewModel: PostchainViewModel, currentPageIndex: Binding<Int>) -> some View {
        modifier(AutoAdvanceModifier(aiMessage: aiMessage, viewModel: viewModel, currentPageIndex: currentPageIndex))
    }
}

// MARK: - Preview

#Preview {
    struct AutoAdvancePreview: View {
        @State private var currentPageIndex = 0
        @StateObject private var autoAdvanceManager = TurnAutoAdvanceManager()

        var body: some View {
            VStack(spacing: 20) {
                Text("Auto-Advance Manager Preview")
                    .font(.title)

                Text("Current Page: \(currentPageIndex)")
                    .font(.headline)

                Text("Auto-Advance Enabled: \(autoAdvanceManager.isAutoAdvanceEnabled ? "Yes" : "No")")
                    .foregroundColor(autoAdvanceManager.isAutoAdvanceEnabled ? .green : .red)

                Text("Manual Navigation: \(autoAdvanceManager.hasUserNavigatedManually ? "Yes" : "No")")
                    .foregroundColor(autoAdvanceManager.hasUserNavigatedManually ? .orange : .blue)

                HStack {
                    Button("Previous Page") {
                        if currentPageIndex > 0 {
                            currentPageIndex -= 1
                        }
                    }
                    .disabled(currentPageIndex <= 0)

                    Button("Next Page") {
                        if currentPageIndex < 4 {
                            currentPageIndex += 1
                        }
                    }
                    .disabled(currentPageIndex >= 4)
                }

                Button("Reset Auto-Advance") {
                    autoAdvanceManager.resetAutoAdvance()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .onChange(of: currentPageIndex) { _, newIndex in
                autoAdvanceManager.currentPageIndex = newIndex
            }
        }
    }

    return AutoAdvancePreview()
}
