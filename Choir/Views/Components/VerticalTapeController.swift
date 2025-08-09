import SwiftUI

/// Unified vertical tape controller rendering all turns as virtual pages
/// Eliminates horizontal navigation; pages advance only at content boundaries.
struct VerticalTapeController: View {
    let thread: ChoirThread
    @ObservedObject var viewModel: PostchainViewModel

    // Global page navigation across the entire conversation
    @State private var currentPageIndex: Int = 0
    @State private var pages: [VirtualPage] = []

    // Auto-advance within the active AI turn
    @StateObject private var autoAdvanceManager = TurnAutoAdvanceManager()

    var body: some View {
        ZStack(alignment: .top) {
            // Main pager of all virtual pages
            PageNavigationController(
                pages: pages.map { AnyView(pageView(for: $0)) },
                currentPageIndex: $currentPageIndex
            ) { index, pageView in
                pageView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }

            // Metadata bar overlay for position and fast navigation
            if !pages.isEmpty {
                MetadataBar(
                    title: addressTitle(for: currentPageIndex),
                    totalPages: pages.count,
                    currentIndex: $currentPageIndex
                )
                .padding(.horizontal, 8)
                .padding(.top, 6)
            }
        }
        .onAppear {
            rebuildPages(keepPosition: true)
            setupAutoAdvanceForCurrentTurn()
            // Default to latest page when opening a thread with content
            if !pages.isEmpty { currentPageIndex = pages.count - 1 }
        }
        .onChange(of: thread.messages) { _, _ in
            let priorAddress = pages.indices.contains(currentPageIndex) ? pages[currentPageIndex].address : nil
            rebuildPages(keepPosition: true, preferAddress: priorAddress)
            setupAutoAdvanceForCurrentTurn()
        }
        .onChange(of: currentPageIndex) { _, _ in
            // Keep auto-advance aligned with currently focused turn
            setupAutoAdvanceForCurrentTurn()
        }
        .onChange(of: autoAdvanceManager.currentPageIndex) { _, newRelative in
            // Update global page index when auto-advance moves within the current turn
            let (base, _) = currentTurnBaseIndexAndAI()
            guard let baseIndex = base else { return }
            let target = baseIndex + newRelative
            if pages.indices.contains(target) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    currentPageIndex = target
                }
            }
        }
    }

    // MARK: - Page Composition

    private func rebuildPages(keepPosition: Bool, preferAddress: VirtualPageAddress? = nil) {
        var newPages: [VirtualPage] = []
        var currentUserMessage: Message?
        var turnNumber = 0

        for message in thread.messages {
            if message.isUser {
                currentUserMessage = message
                turnNumber += 1
                // Page 1: User
                newPages.append(VirtualPage(
                    address: VirtualPageAddress(turn: turnNumber, kind: .user),
                    userMessage: message,
                    aiMessage: nil
                ))
            } else if let user = currentUserMessage {
                // AI response pages for this turn
                let ai = message

                // Page 2: Action
                if ai.isStreaming || hasContent(.action, in: ai) {
                    newPages.append(VirtualPage(address: .init(turn: turnNumber, kind: .action), userMessage: user, aiMessage: ai))
                }
                // Page 3: Experience (vectors/web)
                if ai.isStreaming || hasExperienceContent(in: ai) {
                    newPages.append(VirtualPage(address: .init(turn: turnNumber, kind: .experience), userMessage: user, aiMessage: ai))
                }
                // Page 4: IOU
                if ai.isStreaming || hasIOUContent(in: ai) {
                    newPages.append(VirtualPage(address: .init(turn: turnNumber, kind: .iou), userMessage: user, aiMessage: ai))
                }
                // Page 5: Yield
                if ai.isStreaming || hasContent(.yield, in: ai) {
                    newPages.append(VirtualPage(address: .init(turn: turnNumber, kind: .yield), userMessage: user, aiMessage: ai))
                }

                // Reset until next user message
                currentUserMessage = nil
            }
        }

        // Handle trailing user message with no AI yet
        if let user = currentUserMessage {
            turnNumber += 0 // turnNumber already incremented when user message was seen
            // Only the user page exists so far
            if !newPages.contains(where: { $0.address.turn == turnNumber && $0.address.kind == .user }) {
                newPages.append(VirtualPage(address: .init(turn: turnNumber, kind: .user), userMessage: user, aiMessage: nil))
            }
        }

        // Preserve position
        let oldAddress = preferAddress
        let newIndex: Int = {
            if let old = oldAddress, let idx = newPages.firstIndex(where: { $0.address == old }) {
                return idx
            } else {
                return min(currentPageIndex, max(0, newPages.count - 1))
            }
        }()

        pages = newPages
        currentPageIndex = newIndex
    }

    @ViewBuilder
    private func pageView(for page: VirtualPage) -> some View {
        // Wrap each page with a header separator showing the address
        VStack(spacing: 0) {
            PageSeparator(addressText: page.address.displayTitle)
                .padding(.horizontal, 12)
                .padding(.top, 32) // Ensure space below MetadataBar
                .padding(.bottom, 6)

            Group {
                switch page.address.kind {
                case .user:
                    UserMessagePageView(message: page.userMessage!) { direction in
                        handleBoundaryNavigation(direction)
                    }
                case .action:
                    if let ai = page.aiMessage {
                        ActionPageView(message: ai, viewModel: viewModel) { direction in
                            handleBoundaryNavigation(direction)
                        }
                    }
                case .experience:
                    if let ai = page.aiMessage {
                        ExperiencePageView(message: ai, viewModel: viewModel) { direction in
                            handleBoundaryNavigation(direction)
                        }
                    }
                case .iou:
                    if let ai = page.aiMessage {
                        IOUPageView(message: ai, viewModel: viewModel) { direction in
                            handleBoundaryNavigation(direction)
                        }
                    }
                case .yield:
                    if let ai = page.aiMessage {
                        YieldPageView(message: ai, viewModel: viewModel) { direction in
                            handleBoundaryNavigation(direction)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func handleBoundaryNavigation(_ direction: PageAwareScrollView<AnyView>.PageNavigationDirection) {
        switch direction {
        case .previous:
            if currentPageIndex > 0 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    currentPageIndex -= 1
                }
                autoAdvanceManager.markManualNavigation()
            }
        case .next:
            if currentPageIndex < pages.count - 1 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    currentPageIndex += 1
                }
                autoAdvanceManager.markManualNavigation()
            }
        }
    }

    // MARK: - Auto-advance bridging (global index)

    private func setupAutoAdvanceForCurrentTurn() {
        guard !pages.isEmpty else { return }
        let (turnStart, aiMessage) = currentTurnBaseIndexAndAI()
        guard let baseIndex = turnStart, let ai = aiMessage else {
            autoAdvanceManager.stopMonitoring()
            return
        }

        // Map current global index into relative page index within this turn
        let relative = max(0, currentPageIndex - baseIndex)
        autoAdvanceManager.currentPageIndex = relative
        autoAdvanceManager.startMonitoring(for: ai, viewModel: viewModel)

        // Observe auto-advance changes and bump global index accordingly
        // Note: We rely on onChange in TurnAutoAdvanceManager's ViewModifier in other places;
        // here we mirror the behavior manually by reacting to published changes using onReceive via .onChange
    }

    private func currentTurnBaseIndexAndAI() -> (Int?, Message?) {
        guard pages.indices.contains(currentPageIndex) else { return (nil, nil) }
        let addr = pages[currentPageIndex].address
        // Find the first page index of this turn
        if let startIdx = pages.firstIndex(where: { $0.address.turn == addr.turn && $0.address.kind == .user }) {
            // Find AI message for this turn (the first non-user page owns the AI message)
            let ai = pages.first(where: { $0.address.turn == addr.turn && $0.aiMessage != nil })?.aiMessage
            return (startIdx, ai)
        }
        return (nil, nil)
    }

    // MARK: - Helpers

    private func addressTitle(for index: Int) -> String {
        guard pages.indices.contains(index) else { return "" }
        return pages[index].address.displayTitle
    }

    private func hasContent(_ phase: Phase, in message: Message) -> Bool {
        return !message.getPhaseContent(phase).isEmpty
    }

    private func hasExperienceContent(in message: Message) -> Bool {
        return !message.getPhaseContent(.experienceVectors).isEmpty ||
               !message.getPhaseContent(.experienceWeb).isEmpty
    }

    private func hasIOUContent(in message: Message) -> Bool {
        return !message.getPhaseContent(.intention).isEmpty ||
               !message.getPhaseContent(.observation).isEmpty ||
               !message.getPhaseContent(.understanding).isEmpty
    }
}

// MARK: - Models

private struct VirtualPage: Identifiable, Equatable {
    let id = UUID()
    let address: VirtualPageAddress
    let userMessage: Message?
    let aiMessage: Message?

    static func == (lhs: VirtualPage, rhs: VirtualPage) -> Bool {
        lhs.address == rhs.address && lhs.userMessage?.id == rhs.userMessage?.id && lhs.aiMessage?.id == rhs.aiMessage?.id
    }
}

private struct VirtualPageAddress: Equatable {
    enum Kind: Int, CaseIterable { case user = 1, action, experience, iou, yield }
    let turn: Int
    let kind: Kind

    var displayTitle: String {
        "Turn \(turn): Page \(kind.rawValue)"
    }
}

// MARK: - UI Components

private struct PageSeparator: View {
    let addressText: String
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 1)
            Text(addressText)
                .font(.caption)
                .foregroundColor(.secondary)
            Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 1)
        }
    }
}

struct MetadataBar: View {
    let title: String
    let totalPages: Int
    @Binding var currentIndex: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(currentIndex + 1)/\(totalPages)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)

            // Simple scrubber for fast navigation
            Slider(value: Binding(
                get: { Double(currentIndex) },
                set: { newVal in
                    let clamped = min(max(Int(newVal.rounded()), 0), max(0, totalPages - 1))
                    if clamped != currentIndex {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentIndex = clamped
                        }
                    }
                }
            ), in: 0...Double(max(0, totalPages - 1)), step: 1)
            .tint(.accentColor)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    let previewThread = ChoirThread(title: "Sample Conversation")
    let userMessage1 = Message(content: "What is artificial intelligence?", isUser: true)
    let aiMessage1 = Message(content: "", isUser: false)
    aiMessage1.phaseResults[.action] = PhaseResult(content: "AI is...", provider: "OpenAI", modelName: "gpt-4")
    aiMessage1.phaseResults[.yield] = PhaseResult(content: "Artificial intelligence refers to...", provider: "OpenAI", modelName: "gpt-4")

    let userMessage2 = Message(content: "How does machine learning work?", isUser: true)
    let aiMessage2 = Message(content: "", isUser: false)
    aiMessage2.phaseResults[.action] = PhaseResult(content: "Machine learning works by...", provider: "OpenAI", modelName: "gpt-4")

    previewThread.messages = [userMessage1, aiMessage1, userMessage2, aiMessage2]

    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())

    return VerticalTapeController(thread: previewThread, viewModel: previewViewModel)
}
