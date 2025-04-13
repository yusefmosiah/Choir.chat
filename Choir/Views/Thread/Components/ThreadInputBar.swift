import SwiftUI

struct ThreadInputBar: View {
    @Binding var input: String
    let isProcessing: Bool
    let onSend: (String) async -> Void
    let onCancel: () -> Void
    
    // Optional processing status for large inputs
    var processingStatus: String = ""
    var isProcessingLargeInput: Bool = false
    
    // State to track input height
    @State private var textEditorHeight: CGFloat = 40
    // State to track character count
    @State private var characterCount: Int = 0
    
    // Maximum input height
    private let maxHeight: CGFloat = 120
    // Warning threshold for character count
    private let characterWarningThreshold: Int = 2000
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom) {
                ZStack(alignment: .topLeading) {
                    // Invisible text view to measure height
                    Text(input.isEmpty ? "Message" : input)
                        .padding(6)
                        .foregroundColor(.clear)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(
                                key: ViewHeightKey.self,
                                value: geometry.size.height
                            )
                        })
                    
                    // Actual input editor
                    TextEditor(text: $input)
                        .frame(height: min(textEditorHeight, maxHeight))
                        .scrollContentBackground(.hidden)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .disabled(isProcessing)
                        .onChange(of: input) { _, newValue in
                            characterCount = newValue.count
                        }
                }
                .frame(minHeight: 40, maxHeight: min(textEditorHeight, maxHeight))
                .onPreferenceChange(ViewHeightKey.self) { height in
                    textEditorHeight = min(height + 16, maxHeight)
                }
                
                if isProcessing {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                } else {
                    Button("Send") {
                        guard !input.isEmpty else { return }
                        let messageContent = input
                        input = "" // Clear input immediately
                        
                        Task {
                            await onSend(messageContent)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Character counter with warning
            if characterCount > 0 {
                HStack {
                    Spacer()
                    Text("\(characterCount) characters")
                        .font(.caption)
                        .foregroundColor(
                            characterCount > characterWarningThreshold ? .red : .secondary
                        )
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
            }
        }
        .padding()
    }
}

// Height preference key for dynamic sizing
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
