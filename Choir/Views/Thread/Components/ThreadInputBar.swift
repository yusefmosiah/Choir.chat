import SwiftUI

struct ThreadInputBar: View {
    @Binding var input: String
    let isProcessing: Bool
    let onSend: (String) async -> Void
    let onCancel: () -> Void
    
    // Optional processing status for large inputs
    var processingStatus: String = ""
    var isProcessingLargeInput: Bool = false
    
    // Track text editor focus
    @FocusState private var isFocused: Bool
    
    // Internal state for tracking
    @State private var contentHeight: CGFloat = 36
    @State private var isLargeInput: Bool = false
    
    // Constants
    private let minHeight: CGFloat = 36
    private let maxHeight: CGFloat = 200
    private let largeInputThreshold: Int = 10000
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom) {
                // Main input field container
                ZStack(alignment: .topLeading) {
                    // Background for the text editor
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.secondarySystemBackground))
                    
                    // Placeholder text when empty
                    if input.isEmpty {
                        Text("Type your message here...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 10)
                    }
                    
                    // Actual text editor with scroll capabilities for long inputs
                    TextEditor(text: $input)
                        .padding(.horizontal, 4)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($isFocused)
                        .disabled(isProcessing)
                        .onChange(of: input) { oldValue, newValue in
                            // Update is large input state
                            isLargeInput = newValue.count > largeInputThreshold
                            
                            // Animate the height change
                            withAnimation(.easeInOut(duration: 0.15)) {
                                updateHeight(for: newValue)
                            }
                        }
                }
                .frame(height: contentHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Send/Cancel button
                if isProcessing {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding(.bottom, 2)
                } else {
                    Button {
                        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        
                        // Store the message content before clearing the input
                        let messageContent = input
                        input = "" // Clear input immediately
                        
                        // Reset height after clearing input
                        withAnimation(.easeInOut(duration: 0.2)) {
                            contentHeight = minHeight
                        }
                        
                        // Send the message
                        Task {
                            await onSend(messageContent)
                        }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(8)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(Circle())
                    .padding(.bottom, 2)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            
            // Processing status for large inputs
            if isProcessingLargeInput && !processingStatus.isEmpty {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, 4)
                    
                    Text(processingStatus)
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
            
            // Warning for very large inputs
            if isLargeInput {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Large messages may take longer to process")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
    
    // Update the content height based on text
    private func updateHeight(for text: String) {
        // Count lines in text
        let lineCount = max(1, text.split(separator: "\n").count)
        
        // Calculate height based on line count - average line height is about 20 points
        let calculatedHeight = CGFloat(lineCount) * 20 + 16
        
        // Apply min/max constraints
        contentHeight = max(minHeight, min(calculatedHeight, maxHeight))
    }
}

#Preview {
    VStack {
        Spacer()
        ThreadInputBar(
            input: .constant(""),
            isProcessing: false,
            onSend: { _ in },
            onCancel: {}
        )
    }
    .background(Color.gray.opacity(0.1))
}