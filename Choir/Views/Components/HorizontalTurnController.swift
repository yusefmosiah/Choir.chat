import SwiftUI

/// Controller for horizontal navigation between conversation turns
/// Each turn contains a TurnContainerView with 5 vertical pages
struct HorizontalTurnController: View {
    let thread: ChoirThread
    @ObservedObject var viewModel: PostchainViewModel

    // Turn navigation state
    @State private var currentTurnIndex: Int = 0
    @State private var conversationTurns: [ConversationTurn] = []
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating: Bool = false

    // Configuration
    private let swipeThreshold: CGFloat = 80
    private let elasticLimit: CGFloat = 120
    private let animationDuration: Double = 0.4

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(conversationTurns.indices, id: \.self) { index in
                    let turn = conversationTurns[index]

                    TurnContainerView(
                        userMessage: turn.userMessage,
                        aiMessage: turn.aiMessage,
                        viewModel: viewModel
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: calculateTurnOffset(for: index, containerWidth: geometry.size.width))
                    .opacity(calculateTurnOpacity(for: index))
                    .allowsHitTesting(index == currentTurnIndex)
                    .clipped()
                }
            }
            .clipped()
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        handleDragChanged(value, containerWidth: geometry.size.width)
                    }
                    .onEnded { value in
                        handleDragEnded(value, containerWidth: geometry.size.width)
                    }
            )
        }
        .onAppear {
            updateConversationTurns()
            // Navigate to the most recent turn
            if !conversationTurns.isEmpty {
                currentTurnIndex = conversationTurns.count - 1
            }
        }
        .onChange(of: thread.messages) { _, _ in
            updateConversationTurns()
        }
        .onChange(of: currentTurnIndex) { _, newIndex in
            // Ensure the index is within bounds
            if newIndex < 0 {
                currentTurnIndex = 0
            } else if newIndex >= conversationTurns.count {
                currentTurnIndex = max(0, conversationTurns.count - 1)
            }
        }
    }

    // MARK: - Turn Management

    private func updateConversationTurns() {
        var turns: [ConversationTurn] = []
        var currentUserMessage: Message?

        for message in thread.messages {
            if message.isUser {
                currentUserMessage = message
            } else if let userMessage = currentUserMessage {
                // Create a turn with the user message and AI response
                let turn = ConversationTurn(
                    id: "turn_\(userMessage.id)_\(message.id)",
                    userMessage: userMessage,
                    aiMessage: message
                )
                turns.append(turn)
                currentUserMessage = nil
            }
        }

        // Handle case where there's a user message without an AI response yet
        if let userMessage = currentUserMessage {
            // Create a turn with an empty AI message for streaming
            let emptyAIMessage = Message(content: "", isUser: false)
            let turn = ConversationTurn(
                id: "turn_\(userMessage.id)_pending",
                userMessage: userMessage,
                aiMessage: emptyAIMessage
            )
            turns.append(turn)
        }

        let wasAtEnd = currentTurnIndex >= conversationTurns.count - 1
        conversationTurns = turns

        // If we were at the end, stay at the end
        if wasAtEnd && !conversationTurns.isEmpty {
            currentTurnIndex = conversationTurns.count - 1
        } else if currentTurnIndex >= conversationTurns.count {
            currentTurnIndex = max(0, conversationTurns.count - 1)
        }
    }

    // MARK: - Gesture Handling

    private func handleDragChanged(_ value: DragGesture.Value, containerWidth: CGFloat) {
        guard !isAnimating else { return }

        let translation = value.translation.width

        // Apply elastic resistance at boundaries
        if (currentTurnIndex == 0 && translation > 0) ||
           (currentTurnIndex == conversationTurns.count - 1 && translation < 0) {
            // Elastic scrolling at boundaries
            let resistance: CGFloat = 3.0
            let elasticTranslation = translation / resistance
            dragOffset = min(max(elasticTranslation, -elasticLimit), elasticLimit)
        } else {
            // Normal scrolling
            dragOffset = translation
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value, containerWidth: CGFloat) {
        guard !isAnimating else { return }

        let translation = value.translation.width
        let velocity = value.velocity.width

        // Turn change detection
        let velocityThreshold: CGFloat = 300
        let distanceThreshold: CGFloat = swipeThreshold

        let shouldChangeTurn = abs(translation) > distanceThreshold || abs(velocity) > velocityThreshold

        withAnimation(.spring(response: animationDuration, dampingFraction: 0.8)) {
            isAnimating = true

            if shouldChangeTurn {
                if translation > 0 && currentTurnIndex > 0 {
                    // Swipe right - go to previous turn
                    currentTurnIndex -= 1
                    triggerHapticFeedback()
                } else if translation < 0 && currentTurnIndex < conversationTurns.count - 1 {
                    // Swipe left - go to next turn
                    currentTurnIndex += 1
                    triggerHapticFeedback()
                }
            }

            // Reset drag offset
            dragOffset = 0
        }

        // Reset animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            isAnimating = false
        }
    }

    // MARK: - Layout Calculations

    private func calculateTurnOffset(for index: Int, containerWidth: CGFloat) -> CGFloat {
        let turnSpacing: CGFloat = 40 // Add spacing between turns
        let baseOffset = CGFloat(index - currentTurnIndex) * (containerWidth + turnSpacing)
        return baseOffset + dragOffset
    }

    private func calculateTurnOpacity(for index: Int) -> Double {
        let distance = abs(index - currentTurnIndex)

        if distance == 0 {
            return 1.0
        } else if distance == 1 {
            // Show adjacent turns with reduced opacity
            return 0.1
        } else {
            return 0.0
        }
    }

    // MARK: - Helper Methods

    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Supporting Types

struct ConversationTurn: Identifiable {
    let id: String
    let userMessage: Message
    let aiMessage: Message
}

// MARK: - Public Interface

extension HorizontalTurnController {
    /// Navigate to a specific turn with animation
    func navigateToTurn(_ index: Int) {
        guard index != currentTurnIndex && index >= 0 && index < conversationTurns.count else { return }

        withAnimation(.spring(response: animationDuration, dampingFraction: 0.8)) {
            currentTurnIndex = index
        }

        triggerHapticFeedback()
    }

    /// Navigate to the most recent turn
    func navigateToLatestTurn() {
        if !conversationTurns.isEmpty {
            navigateToTurn(conversationTurns.count - 1)
        }
    }

    /// Get the current turn
    var currentTurn: ConversationTurn? {
        guard currentTurnIndex >= 0 && currentTurnIndex < conversationTurns.count else { return nil }
        return conversationTurns[currentTurnIndex]
    }
}

// MARK: - Preview

#Preview {
    let previewThread = ChoirThread(title: "Sample Conversation")

    // Add sample messages
    let userMessage1 = Message(content: "What is artificial intelligence?", isUser: true)
    let aiMessage1 = Message(content: "", isUser: false)
    aiMessage1.phaseResults[.action] = PhaseResult(content: "AI is...", provider: "OpenAI", modelName: "gpt-4")
    aiMessage1.phaseResults[.yield] = PhaseResult(content: "Artificial intelligence refers to...", provider: "OpenAI", modelName: "gpt-4")

    let userMessage2 = Message(content: "How does machine learning work?", isUser: true)
    let aiMessage2 = Message(content: "", isUser: false)
    aiMessage2.phaseResults[.action] = PhaseResult(content: "Machine learning works by...", provider: "OpenAI", modelName: "gpt-4")

    previewThread.messages = [userMessage1, aiMessage1, userMessage2, aiMessage2]

    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())

    return HorizontalTurnController(thread: previewThread, viewModel: previewViewModel)
}
