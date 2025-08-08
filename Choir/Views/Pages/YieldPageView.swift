import SwiftUI

/// Page view for the Yield phase content (final response)
struct YieldPageView: View {
    @ObservedObject var message: Message
    @ObservedObject var viewModel: PostchainViewModel

    // Optional callback for page navigation requests
    var onPageNavigationRequest: ((PageAwareScrollView<AnyView>.PageNavigationDirection) -> Void)? = nil

    private var yieldContent: String {
        message.getPhaseContent(.yield)
    }

    private var hasContent: Bool {
        !yieldContent.isEmpty
    }

    private var isStreaming: Bool {
        message.isStreaming && message.phaseResults[.yield] != nil
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
                        } else if isStreaming {
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
            Image(systemName: "arrow.down.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Final Response")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Comprehensive answer incorporating all analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator
            if isStreaming {
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
        VStack(alignment: .leading, spacing: 16) {
            // Response summary if available
            responseSummary

            // Main yield content
            PaginatedMarkdownView(
                pageContent: yieldContent,
                currentMessage: message
            )
            .frame(maxWidth: .infinity, alignment: .topLeading)

            // Citations and rewards section
            citationsAndRewards


        }
    }

    private var responseSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Response Summary")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()
            }

            HStack(spacing: 16) {
                // Word count
                let wordCount = yieldContent.components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }.count

                HStack(spacing: 4) {
                    Image(systemName: "text.alignleft")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text("\(wordCount) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Character count
                HStack(spacing: 4) {
                    Image(systemName: "character.cursor.ibeam")
                        .font(.caption)
                        .foregroundColor(.green)

                    Text("\(yieldContent.count) chars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var citationsAndRewards: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Citation rewards
            if let citationReward = message.citationReward, !citationReward.isEmpty {
                citationRewardsSection
            }

            // Citation explanations
            if let citationExplanations = message.citationExplanations, !citationExplanations.isEmpty {
                citationExplanationsSection
            }
        }
    }

    private var citationRewardsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.caption)
                    .foregroundColor(.orange)

                Text("Citation Rewards")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()
            }

            if let citationReward = message.citationReward {
                ForEach(Array(citationReward.keys.sorted()), id: \.self) { key in
                    if let value = citationReward[key] {
                        HStack {
                            Text("• \(key):")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(String(describing: value))
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)

                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }

    private var citationExplanationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text("Citation Details")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()
            }

            if let explanations = message.citationExplanations {
                ForEach(Array(explanations.keys.sorted()), id: \.self) { key in
                    if let explanation = explanations[key] {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text(explanation)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }

    private var streamingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generating final response...")
                .font(.body)
                .foregroundColor(.secondary)
                .italic()

            // Animated placeholder content
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 16)
                        .frame(width: CGFloat.random(in: 0.3...0.95) * UIScreen.main.bounds.width)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isStreaming
                        )
                }
            }
            .padding(.top, 8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No final response")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("The final response hasn't been generated yet.")
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
    previewMessage.phaseResults[.yield] = PhaseResult(
        content: "This is a comprehensive final response that incorporates all the analysis from previous phases. It includes **markdown formatting** and provides a thorough answer to the user's question.",
        provider: "OpenAI",
        modelName: "gpt-4"
    )

    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())

    return YieldPageView(message: previewMessage, viewModel: previewViewModel)
}
