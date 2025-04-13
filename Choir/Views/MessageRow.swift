import SwiftUI
import Foundation

struct MessageRow: View {
    @ObservedObject var message: Message
    let isProcessing: Bool
    @ObservedObject var viewModel: PostchainViewModel
    
    // State for lazy loading
    @State private var isVisible = false
    @State private var shouldLoadFullContent = false
    
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
            // AI messages - lazily load PostchainView
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
                
                // Main content area with lazy loading
                ZStack {
                    // Placeholder shown initially or when off-screen
                    if !shouldLoadFullContent {
                        placeholderView
                            .onAppear {
                                isVisible = true
                                // Start loading full content after a short delay when view appears
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if isVisible {
                                        shouldLoadFullContent = true
                                    }
                                }
                            }
                            .onDisappear {
                                isVisible = false
                            }
                    }
                    
                    // Full PostchainView loaded lazily
                    if shouldLoadFullContent {
                        PostchainView(
                            message: message,
                            isProcessing: isProcessing,
                            viewModel: viewModel,
                            localThreadIDs: [],
                            forceShowAllPhases: true,
                            coordinator: viewModel.coordinator as? PostchainCoordinatorImpl,
                            viewId: message.id
                        )
                        .id("postchain_\(message.id)_\(message.phases.hashValue)")
                    }
                }
                .frame(minHeight: 600, maxHeight: .infinity)
                .padding(.top, 4)
                .padding(.trailing, 40)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .padding(.bottom, 8)
    }
    
    // Lightweight placeholder view shown before full content loads
    private var placeholderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Basic preview of content
            Text("AI Response")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Preview content (first part of yield phase if available)
            let previewContent = message.getPhaseContent(.yield).prefix(200)
            Text(previewContent.isEmpty ? "Loading..." : previewContent)
                .lineLimit(5)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    // Mock ViewModel for Preview
    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())
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
