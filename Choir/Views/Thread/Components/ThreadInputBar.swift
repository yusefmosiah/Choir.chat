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

    // Explicitly control when focus can be set
    var allowFocus: Bool = false

    // Internal state for tracking
    @State private var contentHeight: CGFloat = 36
    @State private var isLargeInput: Bool = false

    // Constants
    private let minHeight: CGFloat = 36
    private let maxHeight: CGFloat = 120 // Approximately 4 lines + padding
    private let largeInputThreshold: Int = 10000

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .center, spacing: 12) {
                // Main input field container with neumorphic glass effect
                ZStack(alignment: .topLeading) {
                    // Placeholder text when empty
                    if input.isEmpty {
                        Text("Type your message here...")
                            .foregroundColor(.gray.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }

                    // Actual text editor with scroll capabilities for long inputs
                    TextEditor(text: $input)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .padding(.trailing, 4) // Extra padding on right to ensure cursor is visible
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($isFocused)
                        .disabled(isProcessing)
                        .font(.system(size: 16))
                        .scrollDisabled(false)
                        .scrollIndicators(.automatic)
                        .onAppear {
                            // Explicitly prevent focus when view appears
                            isFocused = false
                            // Set initial height
                            if !input.isEmpty {
                                updateHeight(for: input)
                            }
                        }
                        // Also prevent focus when view updates
                        .onChange(of: isProcessing) { oldValue, newValue in
                            if !newValue { // When processing completes
                                isFocused = false
                            }
                        }
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
                .background(
                    ZStack {
                        // Glass background with neumorphic effect
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground).opacity(0.7))
                            // Add a subtle inner shadow for depth
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    .blur(radius: 1)
                                    .offset(x: 0, y: 1)
                                    .mask(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.black, Color.clear]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )))
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.3), Color.gray.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blur(radius: 0.5)
                )

                // Send/Cancel button with neumorphic style
                if isProcessing {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    // Static gradient for cancel button
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.red, .orange.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .opacity(0.8)

                                    // Glass overlay
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.red.opacity(0.3))
                                        .blur(radius: 0.5)
                                }
                            )
                    }
                    .frame(height: 36) // Fixed height for button
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
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                ZStack {
                                    // Static gradient background
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.green, .blue, .purple]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .opacity(0.8)

                                    // Glass overlay
                                    Circle()
                                        .fill(Color(UIColor.systemBackground).opacity(0.3))
                                        .blur(radius: 0.5)
                                }
                            )
                    }
                    .frame(height: 36) // Fixed height for button
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                }
            }

            // Processing status and warnings with neumorphic style
            if isProcessingLargeInput && !processingStatus.isEmpty {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, 4)

                    Text(processingStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground).opacity(0.7))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .padding(.top, 4)
                .transition(.opacity)
            }

            // Warning for very large inputs
            if isLargeInput {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange.opacity(0.8))
                        .font(.caption)

                    Text("Large messages may take longer to process")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground).opacity(0.7))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 0.5)
                )
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            // Subtle glass background for the entire bar
            Rectangle()
                .fill(Color(UIColor.systemBackground).opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -4)
                .blur(radius: 0.5)
        )
    }

    // Update the content height based on text - more accurate calculation
    private func updateHeight(for text: String) {
        if text.isEmpty {
            contentHeight = minHeight
            return
        }

        // Count explicit line breaks
        let explicitLineBreaks = text.split(separator: "\n").count

        // Estimate additional line breaks from word wrapping
        // This is an approximation - actual wrapping depends on font, device width, etc.
        let averageCharsPerLine = 40
        let lines = text.split(separator: "\n")
        var estimatedWrappedLines = 0

        for line in lines {
            // Calculate how many wrapped lines this single line might take
            let lineLength = line.count
            let wrappedLineCount = max(1, Int(ceil(Double(lineLength) / Double(averageCharsPerLine))))
            estimatedWrappedLines += wrappedLineCount - 1 // -1 because we already counted the explicit break
        }

        // Total estimated line count (explicit breaks + word wrapping)
        let estimatedLineCount = max(1, explicitLineBreaks + estimatedWrappedLines)

        // For height calculation, we limit to maxLines (approximately 4)
        let maxLines = Int((maxHeight - minHeight) / 20) + 1
        let visibleLineCount = min(estimatedLineCount, maxLines)

        // Calculate height based on visible line count
        let calculatedHeight = minHeight + (20 * CGFloat(visibleLineCount - 1))

        // Apply min/max constraints with some padding
        contentHeight = max(minHeight, min(calculatedHeight + 16, maxHeight))
    }
}

#Preview {
    VStack {
        Spacer()

        // Single line state
        ThreadInputBar(
            input: .constant("Hello, this is a single line message"),
            isProcessing: false,
            onSend: { _ in },
            onCancel: {}
        )
        .padding(.bottom, 20)

        // Multiline state (4 lines - maximum)
        ThreadInputBar(
            input: .constant("This is a message with multiple lines.\nIt demonstrates the maximum height.\nThis is the third line of the message.\nAnd this is the fourth line, which is the maximum."),
            isProcessing: false,
            onSend: { _ in },
            onCancel: {}
        )
        .padding(.bottom, 20)

        // Processing state
        ThreadInputBar(
            input: .constant("This is a message being processed"),
            isProcessing: true,
            onSend: { _ in },
            onCancel: {},
            processingStatus: "Processing input...",
            isProcessingLargeInput: true
        )
        .padding(.bottom, 20)

        // Large input warning state
        ThreadInputBar(
            input: .constant("This is a very large message that would trigger the warning"),
            isProcessing: false,
            onSend: { _ in },
            onCancel: {}
        )
        .environment(\.colorScheme, .dark) // Show in dark mode for contrast
    }
    .background(Color(UIColor.systemBackground))
    .padding(.vertical)
}
