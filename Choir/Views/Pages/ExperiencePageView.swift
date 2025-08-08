import SwiftUI

/// Page view for the Experience phase content (combines vector and web search)
struct ExperiencePageView: View {
    @ObservedObject var message: Message
    @ObservedObject var viewModel: PostchainViewModel

    // Optional callback for page navigation requests
    var onPageNavigationRequest: ((PageAwareScrollView<AnyView>.PageNavigationDirection) -> Void)? = nil

    // State for collapsible sections
    @State private var isVectorSectionExpanded: Bool = true
    @State private var isWebSectionExpanded: Bool = true

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
            // Vector search section
            if hasVectorContent || isStreamingVector {
                CollapsibleSection(
                    title: "Vector Search",
                    icon: "doc.text.magnifyingglass",
                    isExpanded: $isVectorSectionExpanded
                ) {
                    vectorSectionContent
                }
                .headerBackground(Color.blue.opacity(0.1))
            }

            // Web search section
            if hasWebContent || isStreamingWeb {
                CollapsibleSection(
                    title: "Web Search",
                    icon: "network",
                    isExpanded: $isWebSectionExpanded
                ) {
                    webSectionContent
                }
                .headerBackground(Color.green.opacity(0.1))
            }


        }
    }

    // MARK: - Helper Properties

    private var hasVectorContent: Bool {
        !vectorContent.isEmpty || !message.vectorSearchResults.isEmpty
    }

    private var hasWebContent: Bool {
        !webContent.isEmpty || !message.webSearchResults.isEmpty
    }

    private var isStreamingVector: Bool {
        message.isStreaming && message.phaseResults[.experienceVectors] != nil
    }

    private var isStreamingWeb: Bool {
        message.isStreaming && message.phaseResults[.experienceWeb] != nil
    }

    // MARK: - Section Content Views

    private var vectorSectionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Vector search results summary
            if !message.vectorSearchResults.isEmpty {
                vectorResultsSummary
            }

            // Vector search content
            if !vectorContent.isEmpty {
                PaginatedMarkdownView(
                    pageContent: vectorContent,
                    currentMessage: message
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            } else if isStreamingVector {
                streamingIndicator(for: "Vector search")
            }
        }
    }

    private var webSectionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Web search results summary
            if !message.webSearchResults.isEmpty {
                webResultsSummary
            }

            // Web search content
            if !webContent.isEmpty {
                PaginatedMarkdownView(
                    pageContent: webContent,
                    currentMessage: message
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            } else if isStreamingWeb {
                streamingIndicator(for: "Web search")
            }
        }
    }

    private func streamingIndicator(for type: String) -> some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Searching \(type.lowercased())...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var vectorResultsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text("\(message.vectorSearchResults.count) documents found")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            // Show formatted vector results if available
            let vectorResults = message.formatVectorResultsToMarkdown()
            if !vectorResults.isEmpty {
                PaginatedMarkdownView(
                    pageContent: vectorResults,
                    currentMessage: message
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var webResultsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .font(.caption)
                    .foregroundColor(.green)

                Text("\(message.webSearchResults.count) web results found")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            // Show formatted web results if available
            let webResults = message.formatWebResultsToMarkdown()
            if !webResults.isEmpty {
                PaginatedMarkdownView(
                    pageContent: webResults,
                    currentMessage: message
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
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
