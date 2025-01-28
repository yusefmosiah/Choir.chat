# Citation Visualization and Handling

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Implement citation visualization and handling in the carousel UI, allowing users to see and interact with prior references while maintaining the quantum harmonic model of knowledge coupling.

## Tasks

### 1. Citation Data Model
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

### 2. Citation UI Components
```swift
struct CitationView: View {
    let citation: Citation
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading) {
            // Citation preview with similarity score
            HStack {
                Text(citation.content)
                    .lineLimit(isExpanded ? nil : 2)
                Spacer()
                Text("\(Int(citation.similarity * 100))%")
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
            withAnimation { isExpanded.toggle() }
        }
    }
}
```

### 3. Citation Navigation
- Implement deep linking to cited messages
- Handle citation preview in carousel
- Support citation search and filtering

## Success Criteria
- Clear citation visualization
- Smooth navigation between citations
- Accurate similarity scores
- Efficient context display
