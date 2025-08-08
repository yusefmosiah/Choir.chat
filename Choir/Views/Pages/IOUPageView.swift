import SwiftUI

/// Page view for the IOU phases (Intention, Observation, Understanding)
struct IOUPageView: View {
    @ObservedObject var message: Message
    @ObservedObject var viewModel: PostchainViewModel

    private var intentionContent: String {
        message.getPhaseContent(.intention)
    }

    private var observationContent: String {
        message.getPhaseContent(.observation)
    }

    private var understandingContent: String {
        message.getPhaseContent(.understanding)
    }

    private var combinedContent: String {
        var content = ""

        if !intentionContent.isEmpty {
            content += "## Intention\n\n\(intentionContent)"
        }

        if !observationContent.isEmpty {
            if !content.isEmpty {
                content += "\n\n"
            }
            content += "## Observation\n\n\(observationContent)"
        }

        if !understandingContent.isEmpty {
            if !content.isEmpty {
                content += "\n\n"
            }
            content += "## Understanding\n\n\(understandingContent)"
        }

        return content
    }

    private var hasContent: Bool {
        !intentionContent.isEmpty || !observationContent.isEmpty || !understandingContent.isEmpty
    }

    private var isStreaming: Bool {
        message.isStreaming && (
            message.phaseResults[.intention] != nil ||
            message.phaseResults[.observation] != nil ||
            message.phaseResults[.understanding] != nil
        )
    }

    var body: some View {
        ScrollView {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    private var pageHeader: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Understanding")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Intention, observation, and understanding analysis")
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
            // Phase progress indicator
            phaseProgressIndicator

            // Main content
            if !combinedContent.isEmpty {
                PaginatedMarkdownView(
                    pageContent: combinedContent,
                    currentMessage: message
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            // Phase metadata
            phaseMetadata
        }
    }

    private var phaseProgressIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Analysis Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()
            }

            HStack(spacing: 12) {
                // Intention phase
                phaseIndicator(
                    title: "Intention",
                    icon: "target",
                    isComplete: !intentionContent.isEmpty,
                    isActive: message.isStreaming && message.phaseResults[.intention] != nil
                )

                // Observation phase
                phaseIndicator(
                    title: "Observation",
                    icon: "eye.fill",
                    isComplete: !observationContent.isEmpty,
                    isActive: message.isStreaming && message.phaseResults[.observation] != nil
                )

                // Understanding phase
                phaseIndicator(
                    title: "Understanding",
                    icon: "checkmark.circle.fill",
                    isComplete: !understandingContent.isEmpty,
                    isActive: message.isStreaming && message.phaseResults[.understanding] != nil
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private func phaseIndicator(title: String, icon: String, isComplete: Bool, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green.opacity(0.2) : Color.secondary.opacity(0.2))
                    .frame(width: 32, height: 32)

                if isActive {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(isComplete ? .green : .secondary)
                }
            }

            Text(title)
                .font(.caption2)
                .foregroundColor(isComplete ? .primary : .secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var streamingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analyzing intention, observation, and understanding...")
                .font(.body)
                .foregroundColor(.secondary)
                .italic()

            // Animated placeholder content
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 16)
                        .frame(width: CGFloat.random(in: 0.4...0.9) * UIScreen.main.bounds.width)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.25),
                            value: isStreaming
                        )
                }
            }
            .padding(.top, 8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No analysis available")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("The intention, observation, and understanding phases haven't been processed yet.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Metadata

    private var phaseMetadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 4)

            HStack {
                Text("Phase Details")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                // Intention phase metadata
                if let intentionPhase = message.phaseResults[.intention] {
                    metadataSection(title: "Intention", phaseResult: intentionPhase)
                }

                // Observation phase metadata
                if let observationPhase = message.phaseResults[.observation] {
                    metadataSection(title: "Observation", phaseResult: observationPhase)
                }

                // Understanding phase metadata
                if let understandingPhase = message.phaseResults[.understanding] {
                    metadataSection(title: "Understanding", phaseResult: understandingPhase)
                }

                // Combined content length
                if !combinedContent.isEmpty {
                    metadataRow(label: "Total Content", value: "\(combinedContent.count) characters")
                }
            }
        }
        .padding(.top, 8)
    }

    private func metadataSection(title: String, phaseResult: PhaseResult) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            if let provider = phaseResult.provider {
                metadataRow(label: "Provider", value: provider)
            }

            if let modelName = phaseResult.modelName {
                metadataRow(label: "Model", value: modelName)
            }

            metadataRow(label: "Content", value: "\(phaseResult.content.count) chars")
        }
        .padding(.leading, 8)
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.caption2)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview {
    let previewMessage = Message(content: "Test message", isUser: false)
    previewMessage.phaseResults[.intention] = PhaseResult(
        content: "This is the intention analysis content.",
        provider: "OpenAI",
        modelName: "gpt-4"
    )
    previewMessage.phaseResults[.observation] = PhaseResult(
        content: "This is the observation analysis content.",
        provider: "OpenAI",
        modelName: "gpt-4"
    )
    previewMessage.phaseResults[.understanding] = PhaseResult(
        content: "This is the understanding analysis content.",
        provider: "OpenAI",
        modelName: "gpt-4"
    )

    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())

    return IOUPageView(message: previewMessage, viewModel: previewViewModel)
}
