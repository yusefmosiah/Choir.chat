import SwiftUI
import Foundation

struct ExperienceSourcesView: View {
    // Use the actual ViewModel type here, not the mock
    @ObservedObject var viewModel: PostchainViewModel
    // Add messageId property to identify which message's sources to display
    var messageId: String?
    
    @State private var expandedSource: String? = nil
    @Environment(\.openURL) var openURL
    
    // Debug state to track renders and array contents
    @State private var debugRenderCount = 0
    
    // Computed properties to get the appropriate sources for this message
    private var currentMessageId: String {
        return messageId ?? viewModel.activeMessageId
    }
    
    private var messageSources: (vectorSources: [String], webSources: [String], vectorResults: [VectorSearchResult], webResults: [SearchResult]) {
        // Access the appropriate collections directly from viewModel
        let vectorResults = viewModel.vectorResultsByMessage[currentMessageId] ?? []
        let webResults = viewModel.webResultsByMessage[currentMessageId] ?? []
        let vectorSources = viewModel.vectorSourcesByMessage[currentMessageId] ?? []
        let webSources = viewModel.webSearchSourcesByMessage[currentMessageId] ?? []
        
        return (vectorSources: vectorSources, webSources: webSources, vectorResults: vectorResults, webResults: webResults)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Experience Content Section - Display the actual experience text content
                if let experienceContent = viewModel.responses[.experience], !experienceContent.isEmpty {
                    Text(experienceContent)
                        .font(.body)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)
                    
                    Divider()
                        .padding(.vertical, 5)
                }
                
                // Debug Section - Only in DEBUG builds
                #if DEBUG
                VStack(alignment: .leading, spacing: 8) {
                    Text("Debug Info (Message: \(currentMessageId))")
                        .font(.headline)
                        .foregroundColor(.red)
                        
                    Text("Render Count: \(debugRenderCount)")
                        .font(.caption)
                    
                    Text("Vector Results: \(messageSources.vectorResults.count)")
                        .font(.caption)
                    
                    Text("Web Results: \(messageSources.webResults.count)")
                        .font(.caption)
                    
                    Text("Vector Sources: \(messageSources.vectorSources.count)")
                        .font(.caption)
                    
                    Text("Web Sources: \(messageSources.webSources.count)")
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .onAppear {
                    debugRenderCount += 1
                    print("📊 ExperienceSourcesView Debug Info for message \(currentMessageId):")
                    print("  - Vector Results: \(messageSources.vectorResults.count)")
                    print("  - Web Results: \(messageSources.webResults.count)")
                    print("  - Vector Sources: \(messageSources.vectorSources.count)")
                    print("  - Web Sources: \(messageSources.webSources.count)")
                }
                #endif
                
                // Direct Vector Results Section - Use actual structured data
                if !messageSources.vectorResults.isEmpty {
                    Section(header: sectionHeader(title: "Vector Results (\(messageSources.vectorResults.count))", icon: "square.stack.3d.up")) {
                        ForEach(messageSources.vectorResults, id: \.content) { result in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(result.content)
                                    .font(.body)
                                
                                HStack {
                                    Text("Score: \(String(format: "%.2f", result.score))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(result.provider ?? "Unknown Source")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                    }
                }
                
                // Direct Web Results Section - Use actual structured data
                if !messageSources.webResults.isEmpty {
                    Section(header: sectionHeader(title: "Web Results (\(messageSources.webResults.count))", icon: "globe")) {
                        ForEach(messageSources.webResults, id: \.url) { result in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(result.title)
                                    .font(.headline)
                                
                                Text(result.content)
                                    .font(.body)
                                    .lineLimit(3)
                                
                                Button(action: {
                                    if let url = URL(string: result.url) {
                                        openURL(url)
                                    }
                                }) {
                                    Text(result.url)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .underline()
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                    }
                }
                
                // Legacy Vector Database Sources Section - Use string arrays
                if !messageSources.vectorSources.isEmpty {
                    Section(header: sectionHeader(title: "Legacy Vector Sources", icon: "square.stack.3d.up.fill")) {
                        ForEach(messageSources.vectorSources, id: \.self) { source in
                            SourceCard(
                                source: source,
                                type: .vector,
                                isExpanded: expandedSource == source,
                                onExpandToggle: { toggleExpand(source) },
                                onViewSource: { viewSource(source) }
                            )
                        }
                    }
                }

                // Legacy Web Search Sources Section - Use string arrays
                if !messageSources.webSources.isEmpty {
                    Section(header: sectionHeader(title: "Legacy Web Sources", icon: "globe.americas.fill")) {
                        ForEach(messageSources.webSources, id: \.self) { source in
                            SourceCard(
                                source: source,
                                type: .web,
                                isExpanded: expandedSource == source,
                                onExpandToggle: { toggleExpand(source) },
                                onViewSource: { viewSource(source) }
                            )
                        }
                    }
                }
                
                // If no sources available, show a message (in non-DEBUG)
                #if !DEBUG
                if messageSources.vectorResults.isEmpty && messageSources.webResults.isEmpty && 
                   messageSources.vectorSources.isEmpty && messageSources.webSources.isEmpty {
                    Text("No source information available for this response.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                #endif
            }
            .padding()
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline)
        .foregroundColor(.accentColor)
        .padding(.bottom, 4)
    }

    private func toggleExpand(_ source: String) {
        withAnimation {
            expandedSource = expandedSource == source ? nil : source
        }
    }

    private func viewSource(_ source: String) {
        if let url = URL(string: source) {
             openURL(url)
        }
    }
}

private struct SourceCard: View {
    enum SourceType {
        case vector
        case web

        var icon: String {
            switch self {
            case .vector: return "point.3.connected.trianglepath.dotted"
            case .web: return "link"
            }
        }

        var color: Color {
            switch self {
            case .vector: return .blue
            case .web: return .green
            }
        }
    }

    let source: String
    let type: SourceType
    let isExpanded: Bool
    let onExpandToggle: () -> Void
    let onViewSource: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)

                Text(source)
                    .font(.subheadline)
                    .lineLimit(isExpanded ? nil : 2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onExpandToggle) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.accentColor)
                }
            }

            if isExpanded {
                Divider()

                HStack {
                    Button(action: onViewSource) {
                        Label("View Source", systemImage: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }

                    Spacer()

                    Text(type == .vector ? "Vector Similarity" : "Web Result")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onExpandToggle)
    }
}
