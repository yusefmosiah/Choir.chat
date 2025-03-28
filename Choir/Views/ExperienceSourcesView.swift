import SwiftUI
import Foundation

struct ExperienceSourcesView: View {
    // Use the actual ViewModel type here, not the mock
    @ObservedObject var viewModel: PostchainViewModel
    // Add messageId property to identify which message's sources to display
    var messageId: String?
    
    // Pagination properties
    @Binding var currentPage: Int
    @State private var totalPages: Int = 1
    
    // Phase navigation callbacks
    var onNavigateToPreviousPhase: (() -> Void)?
    var onNavigateToNextPhase: (() -> Void)?
    
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
        VStack {
            // Content area - displays different content based on current page
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Display content based on current page
                    if currentPage == 0 {
                        // PAGE 1: Experience Content and Summary
                        experienceContentView
                        sourceSummaryView
                    } else if currentPage == 1 && !messageSources.vectorResults.isEmpty {
                        // PAGE 2: Vector Results
                        vectorResultsView
                    } else if currentPage == 2 && !messageSources.webResults.isEmpty {
                        // PAGE 3: Web Results
                        webResultsView
                    } else if currentPage == 3 && (!messageSources.vectorSources.isEmpty || !messageSources.webSources.isEmpty) {
                        // PAGE 4: Legacy Sources
                        legacySourcesView
                    } else {
                        // Fallback for empty pages
                        Text("No additional source information available.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Pagination controls - similar to PaginatedTextView
            HStack {
                Button(action: {
                    if currentPage > 0 {
                        currentPage -= 1
                    } else if let navigateToPrevious = onNavigateToPreviousPhase {
                        // If on first page, navigate to previous phase
                        navigateToPrevious()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.small)
                        .padding(4)
                }
                // Only disable if on first page AND no previous phase callback
                .disabled(currentPage <= 0 && onNavigateToPreviousPhase == nil)
                .foregroundColor(currentPage <= 0 && onNavigateToPreviousPhase == nil ? .gray : .accentColor)
                
                Spacer()
                
                Text("Page \(currentPage + 1) of \(totalPages)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    if currentPage < totalPages - 1 {
                        currentPage += 1
                    } else if let navigateToNext = onNavigateToNextPhase {
                        // If on last page, navigate to next phase
                        navigateToNext()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .padding(4)
                }
                // Only disable if on last page AND no next phase callback
                .disabled(currentPage >= totalPages - 1 && onNavigateToNextPhase == nil)
                .foregroundColor(currentPage >= totalPages - 1 && onNavigateToNextPhase == nil ? .gray : .accentColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemBackground).opacity(0.6))
            .cornerRadius(8)
            .padding(.bottom, 2)
            .padding(.top, 4)
        }
        .onAppear {
            calculateTotalPages()
        }
        .onChange(of: messageSources.vectorResults.count) { _, _ in
            calculateTotalPages()
        }
        .onChange(of: messageSources.webResults.count) { _, _ in
            calculateTotalPages()
        }
        .onChange(of: messageSources.vectorSources.count) { _, _ in
            calculateTotalPages()
        }
        .onChange(of: messageSources.webSources.count) { _, _ in
            calculateTotalPages()
        }
    }
    
    // MARK: - Page Content Views
    
    // Page 1: Experience Content and Summary
    private var experienceContentView: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        }
    }
    
    // Source summary view
    private var sourceSummaryView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Source Information")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 5) {
                if !messageSources.vectorResults.isEmpty {
                    Text("• \(messageSources.vectorResults.count) Vector Results (Page 2)")
                        .font(.subheadline)
                }
                
                if !messageSources.webResults.isEmpty {
                    Text("• \(messageSources.webResults.count) Web Results (Page 3)")
                        .font(.subheadline)
                }
                
                if !messageSources.vectorSources.isEmpty {
                    Text("• \(messageSources.vectorSources.count) Legacy Vector Sources (Page 4)")
                        .font(.subheadline)
                }
                
                if !messageSources.webSources.isEmpty {
                    Text("• \(messageSources.webSources.count) Legacy Web Sources (Page 4)")
                        .font(.subheadline)
                }
                
                if messageSources.vectorResults.isEmpty && messageSources.webResults.isEmpty &&
                   messageSources.vectorSources.isEmpty && messageSources.webSources.isEmpty {
                    Text("No source information available for this response.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
    
    // Page 2: Vector Results
    private var vectorResultsView: some View {
        VStack(alignment: .leading, spacing: 10) {
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
    }
    
    // Page 3: Web Results
    private var webResultsView: some View {
        VStack(alignment: .leading, spacing: 10) {
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
    }
    
    // Page 4: Legacy Sources
    private var legacySourcesView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Legacy Vector Database Sources Section
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

            // Legacy Web Search Sources Section
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
        }
    }

    // MARK: - Helper Methods
    
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
    
    // Calculate total pages based on available content
    private func calculateTotalPages() {
        var pages = 1 // Always have at least page 1 (experience content)
        
        // Add page for vector results if available
        if !messageSources.vectorResults.isEmpty {
            pages += 1
        }
        
        // Add page for web results if available
        if !messageSources.webResults.isEmpty {
            pages += 1
        }
        
        // Add page for legacy sources if available
        if !messageSources.vectorSources.isEmpty || !messageSources.webSources.isEmpty {
            pages += 1
        }
        
        totalPages = pages
        
        // Ensure current page is valid
        if currentPage >= totalPages {
            currentPage = max(0, totalPages - 1)
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
