# Citation Visualization and Handling

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Thread Sheet Implementation](issue_11.md)
- Related to: [Message Type Reconciliation](issue_1.md)

## Description
Implement citation visualization and handling in the UI, allowing users to see and interact with prior references while maintaining the quantum harmonic model of knowledge coupling.

## Current State
- Have Prior type in ChorusModels
- Citations stored in Qdrant
- Need UI representation
- Need interaction model

## Tasks
1. Citation Data Model
   ```swift
   struct Citation: Identifiable {
       let id: UUID
       let sourceMessageId: String
       let targetMessageId: String
       let content: String
       let similarity: Double
       let context: String

       // Link format: choir://choir.chat/<message_id>
       var link: URL {
           URL(string: "choir://choir.chat/\(targetMessageId)")!
       }
   }

   extension ThreadMessage {
       var citations: [Citation] {
           // Parse markdown links from content
           // Format: [cited text](choir://choir.chat/<message_id>)
           // Return array of Citations
       }
   }
   ```

2. Citation View Components
   ```swift
   struct CitationView: View {
       let citation: Citation
       @State private var isExpanded = false

       var body: some View {
           VStack(alignment: .leading) {
               // Citation preview
               HStack {
                   Text(citation.content)
                       .lineLimit(isExpanded ? nil : 2)
                   Spacer()
                   Text(String(format: "%.0f%%", citation.similarity * 100))
                       .foregroundColor(.secondary)
               }

               // Expanded context
               if isExpanded {
                   Text(citation.context)
                       .padding(.top, 4)
                       .foregroundColor(.secondary)
               }
           }
           .onTapGesture {
               withAnimation {
                   isExpanded.toggle()
               }
           }
       }
   }

   struct MessageCitationsView: View {
       let message: ThreadMessage

       var body: some View {
           if !message.citations.isEmpty {
               VStack(alignment: .leading, spacing: 8) {
                   Text("Citations")
                       .font(.headline)

                   ForEach(message.citations) { citation in
                       CitationView(citation: citation)
                           .padding(.vertical, 4)
                   }
               }
               .padding()
               .background(Color(.systemBackground))
               .cornerRadius(8)
           }
       }
   }
   ```

3. Citation Interaction
   ```swift
   class CitationManager: ObservableObject {
       @Published private(set) var activeCitations: [Citation] = []
       private let api: ChorusAPIClient

       func loadCitation(_ link: URL) async throws {
           guard let messageId = link.lastPathComponent else { return }
           let message = try await api.getMessage(messageId)
           // Create and add citation
       }

       func navigateToCitation(_ citation: Citation) {
           // Handle navigation to cited message
       }
   }
   ```

## Testing Requirements
1. Citation Parsing
   - Markdown link extraction
   - URL validation
   - Content parsing

2. UI Components
   - Layout rendering
   - Expansion behavior
   - Navigation handling

3. Interaction Flow
   - Citation loading
   - Navigation
   - Error handling

## Success Criteria
- Clean citation visualization
- Smooth interaction flow
- Clear relationship display
- Performance with many citations
