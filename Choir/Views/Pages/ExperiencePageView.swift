import SwiftUI

/// Page view for the Experience phase content (combines vector and web search)
struct ExperiencePageView: View {
    @ObservedObject var message: Message
    @ObservedObject var viewModel: PostchainViewModel

    private var vectorContent: String {
        message.getPhaseContent(.experienceVectors)
    }

    private var webContent: String {
        message.getPhaseContent(.experienceWeb)
    }

    private var combinedContent: String {
        var content = ""

        // Add vector search content
        if !vectorContent.isEmpty {
            content += vectorContent
        }

        // Add web search content
        if !webContent.isEmpty {
            if !content.isEmpty {
                content += "\n\n"
            }
            content += webContent
        }

        // Add formatted search results
        let vectorResults = message.formatVectorResultsToMarkdown()
        let webResults = message.formatWebResultsToMarkdown()

        if !vectorResults.isEmpty {
            if !content.isEmpty {
                content += "\n\n"
            }
            content += vectorResults
        }

        if !webResults.isEmpty {
            if !content.isEmpty {
                content += "\n\n"
            }
            content += webResults
        }

        return content
    }

    private var hasContent: Bool {
        !combinedContent.isEmpty || !message.vectorSearchResults.isEmpty || !message.webSearchResults.isEmpty
    }

    private var isStreaming: Bool {
        message.isStreaming && (
            message.phaseResults[.experienceVectors] != nil ||
            message.phaseResults[.experienceWeb] != nil
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
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Research & Analysis")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Vector search and web research results")
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
            // Search results summary
            searchResultsSummary

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

    private var searchResultsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Search Results")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()
            }

            HStack(spacing: 16) {
                // Vector search results count
                if !message.vectorSearchResults.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.caption)
                            .foregroundColor(.blue)

                        Text("\(message.vectorSearchResults.count) docs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Web search results count
                if !message.webSearchResults.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "network")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text("\(message.webSearchResults.count) web")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Novelty reward if available
            if let reward = message.noveltyReward, reward.success {
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text("Earned \(reward.formattedAmount) CHOIR")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var streamingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Searching for relevant information...")
                .font(.body)
                .foregroundColor(.secondary)
                .italic()

            // Animated placeholder content
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 16)
                        .frame(width: CGFloat.random(in: 0.5...0.95) * UIScreen.main.bounds.width)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                            value: isStreaming
                        )
                }
            }
            .padding(.top, 8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No research results")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("No vector or web search results are available for this message.")
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
                // Vector phase metadata
                if let vectorPhase = message.phaseResults[.experienceVectors] {
                    metadataSection(title: "Vector Search", phaseResult: vectorPhase)
                }

                // Web phase metadata
                if let webPhase = message.phaseResults[.experienceWeb] {
                    metadataSection(title: "Web Search", phaseResult: webPhase)
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
    previewMessage.phaseResults[.experienceVectors] = PhaseResult(
        content: "Vector search results content",
        provider: "OpenAI",
        modelName: "text-embedding-ada-002"
    )
    previewMessage.phaseResults[.experienceWeb] = PhaseResult(
        content: "Web search results content",
        provider: "Tavily",
        modelName: "web-search"
    )

    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())

    return ExperiencePageView(message: previewMessage, viewModel: previewViewModel)
}
