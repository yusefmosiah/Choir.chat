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
                    
                    // Actual text editor
                    TextEditor(text: $input)
                        .padding(.horizontal, 4)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 36)
                        .focused($isFocused)
                        .disabled(isProcessing)
                }
                .frame(height: min(max(36, calculateHeight(for: input)), 200))
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
                        let messageContent = input
                        input = "" // Clear input immediately
                        
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
    
    // Calculate height based on text content
    private func calculateHeight(for text: String) -> CGFloat {
        let estimatedHeight = text.isEmpty ? 36 : min(CGFloat(text.filter { $0 == "\n" }.count + 1) * 20 + 16, 200)
        return estimatedHeight
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