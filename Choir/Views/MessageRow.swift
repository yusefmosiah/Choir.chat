import SwiftUI

struct MessageRow: View {
    @ObservedObject var message: Message
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
                    Text(LocalizedStringKey(message.content))
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
                .frame(height: 400)
                .padding(.top, 4)
                .padding(.trailing, 40)
            }

            // Timestamp removed to save space
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .padding(.bottom, 24)
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
        isUser: false,
        phases: [
            .action: "Action phase content.",
            .experience: "Experience phase content.",
            .yield: "Final yield content."
        ]
    )

    return ScrollView { // Wrap in ScrollView for context
        VStack {
            MessageRow(message: userMessage, viewModel: previewViewModel)
            MessageRow(message: aiMessage, isProcessing: true, viewModel: previewViewModel)
            MessageRow(message: aiMessage, isProcessing: false, viewModel: previewViewModel)
        }
        .padding()
    }
}
