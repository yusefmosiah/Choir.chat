import SwiftUI

/// Page view for the Action phase content
struct ActionPageView: View {
    @ObservedObject var message: Message
    @ObservedObject var viewModel: PostchainViewModel

    // Optional callback for page navigation requests
    var onPageNavigationRequest: ((PageAwareScrollView<AnyView>.PageNavigationDirection) -> Void)? = nil

    private var actionContent: String {
        message.getPhaseContent(.action)
    }

    private var hasContent: Bool {
        !actionContent.isEmpty
    }

    var body: some View {
        PageAwareScrollView(
            content: {
                AnyView(
                    VStack(alignment: .leading, spacing: 16) {
                        // Page header
                        pageHeader

                        // Content area
                        if hasContent {
                            contentView
                        } else if message.isStreaming {
                            streamingPlaceholder
                        } else {
                            emptyStateView
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                )
            },
            onPageNavigationRequest: { direction in
                onPageNavigationRequest?(direction)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    private var pageHeader: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Initial Response")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("First thoughts and immediate analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator
            if message.isStreaming {
                ProgressView()
                    .scaleEffect(0.8)
            } else if hasContent {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main action content
            PaginatedMarkdownView(
                pageContent: actionContent,
                currentMessage: message
            )
            .frame(maxWidth: .infinity, alignment: .topLeading)


        }
    }

    private var streamingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generating initial response...")
                .font(.body)
                .foregroundColor(.secondary)
                .italic()

            // Animated placeholder content
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 16)
                        .frame(width: CGFloat.random(in: 0.6...0.9) * UIScreen.main.bounds.width)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: message.isStreaming
                        )
                }
            }
            .padding(.top, 8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No initial response available")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("This phase hasn't been processed yet.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }


}

#Preview {
    let previewMessage = Message(content: "Test message", isUser: false)
    previewMessage.phaseResults[.action] = PhaseResult(
        content: "This is a sample action response with some **markdown** content.",
        provider: "OpenAI",
        modelName: "gpt-4"
    )

    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())

    return ActionPageView(message: previewMessage, viewModel: previewViewModel)
}
