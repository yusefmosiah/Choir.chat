import SwiftUI
import Foundation

struct MessageRow: View {
    @ObservedObject var message: Message
    // Removed thread reference
    let isProcessing: Bool
    @ObservedObject var viewModel: PostchainViewModel

    init(message: Message, isProcessing: Bool = false, viewModel: PostchainViewModel) {
        self.message = message
        self.isProcessing = isProcessing
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            // User messages
            if message.isUser {
                HStack(alignment: .top, spacing: 8) {
                    // Determine the text view content conditionally
                    let textView: Text = {
                        if message.content.count > 4000 {
                            let first100 = message.content.prefix(100)
                            let last100 = message.content.suffix(100)
                            let collapsedText = "<long_text>\(first100)...\(last100)</long_text>"
                            return Text(collapsedText).italic()
                        } else {
                            return Text(LocalizedStringKey(message.content))
                        }
                    }() // Immediately execute the closure

                    // Apply modifiers to the resulting Text view
                    textView
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)

                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.white)
                        .opacity(0.8)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(16) // Use standard cornerRadius
                .padding(.leading, 40)
                .onLongPressGesture {
                    // On long press, use the shared TextSelectionManager to show the text selection options
                    TextSelectionManager.shared.showSheet(withText: message.content)
                }
                .contextMenu {
                    Button("Copy Content") {
                        UIPasteboard.general.string = message.content
                    }

                    Button("Select Text...") {
                        TextSelectionManager.shared.showSheet(withText: message.content)
                    }
                }
            }
            // AI messages - directly show the chorus cycle
            else {
                // Header with AI icon
                HStack {
                    Spacer()

                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if !message.isUser {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)

                // Postchain view - pass the message directly
                let isActive = message.id == viewModel.coordinator.activeMessageId

                // Use the message directly with the new PostchainView
                PostchainView(
                    message: message,
                    isProcessing: isProcessing,
                    viewModel: viewModel, // Pass viewModel
                    localThreadIDs: [],
                    forceShowAllPhases: true,
                    coordinator: viewModel.coordinator as? RESTPostchainCoordinator,
                    viewId: message.id // Use message ID as the view ID for uniqueness
                )
                .id("postchain_\(message.id)_\(message.phases.hashValue)_\(UUID())") // Even more reliable tracking
                .onAppear {
                    // Add additional logging about active phases on view appear
                    print("MessageRow.onAppear: Message \(message.id)")
                    print("  - isActive: \(isActive), isProcessing: \(isProcessing)")
                    print("  - Stored phases in message: \(message.phases.filter { !$0.value.isEmpty }.count)")
                    print("  - View model phases: \(viewModel.responses.count)")
                }
                .onChange(of: isProcessing) { _, newValue in
                    // No-op
                }
                .onChange(of: viewModel.responses) { _, newResponses in
                    // No-op
                }
                .frame(minHeight: 600, maxHeight: .infinity) // Use a taller minimum height with ability to grow
                .padding(.top, 4)
                .padding(.trailing, 40)
            }

            // Timestamp removed to save space
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .padding(.bottom, 8) // Reduced from 24 to 8
    }
}



#Preview {
    // Mock ViewModel for Preview
    let previewViewModel = PostchainViewModel(coordinator: RESTPostchainCoordinator())
    // Add mock data if needed
    // previewViewModel.vectorSources = ["Mock Vector Source"]
    // previewViewModel.webSearchSources = ["https://mock.web.source"]

    // Mock User Message
    let userMessage = Message(
        content: "This is a user message.",
        isUser: true
    )

    // Mock AI Message with phases
    let aiMessage = Message(
        content: "This is the initial AI response.",
        isUser: false
    )

    // let previewThread = ChoirThread() // No longer needed

    ScrollView { // Wrap in ScrollView for context // Removed explicit return
        VStack {
            MessageRow(message: userMessage, isProcessing: false, viewModel: previewViewModel) // Removed isProcessing=true from aiMessage
            MessageRow(message: aiMessage, isProcessing: false, viewModel: previewViewModel) // Removed isProcessing=true from aiMessage
            MessageRow(message: aiMessage, isProcessing: false, viewModel: previewViewModel)
        }
        .padding()
    }
}
