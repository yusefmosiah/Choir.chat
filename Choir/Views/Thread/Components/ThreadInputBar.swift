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

    // Animation state for gradient
    @State private var gradientRotation: Double = 0
    @State private var rotationTimer: Timer?

    // Constants
    private let minHeight: CGFloat = 36
    private let maxLines: Int = 4
    private let lineHeight: CGFloat = 20
    private let maxHeight: CGFloat = 36 + (20 * 3) + 16 // minHeight + (lineHeight * (maxLines-1)) + padding
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
                        // Fix the font to ensure consistent line height calculations
                        .font(.system(size: 16))
                        // Always enable scrolling to ensure cursor visibility
                        .scrollDisabled(false)
                        // Show scrollbar only when needed
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
                                // If input is empty, reset to minimum height
                                if newValue.isEmpty {
                                    contentHeight = minHeight
                                } else {
                                    updateHeight(for: newValue)
                                }
                            }

                            // If text was added (not deleted), ensure cursor is visible by briefly
                            // requesting focus again to trigger scroll-to-cursor behavior
                            if newValue.count > oldValue.count && isFocused {
                                // Use a very short delay to ensure the height update completes first
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    // This trick forces TextEditor to scroll to cursor position
                                    isFocused = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        isFocused = true
                                    }
                                }
                            }
                        }
                }
                .frame(minHeight: minHeight, maxHeight: maxHeight, alignment: .top)
                .frame(height: contentHeight)
                .padding(.vertical, 0) // Remove vertical padding to ensure proper alignment
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
                                    // Angular gradient for processing state
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            AngularGradient(
                                                gradient: Gradient(stops: [
                                                    .init(color: .red, location: 0.0),
                                                    .init(color: .orange, location: 0.5),
                                                    .init(color: .red, location: 1.0),
                                                ]),
                                                center: .center,
                                                angle: .degrees(gradientRotation)
                                            )
                                        )
                                        .blur(radius: 4)
                                        .opacity(0.8)

                                    // Glass overlay
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.red.opacity(0.7))
                                        .blur(radius: 0.5)
                                }
                            )
                    }
                    .frame(height: contentHeight) // Match the height of the input field
                    .onAppear {
                        startRotationTimer()
                    }
                    .onDisappear {
                        stopRotationTimer()
                    }
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
                                    // Angular gradient background
                                    Circle()
                                        .fill(
                                            AngularGradient(
                                                gradient: Gradient(stops: [
                                                    .init(color: .green, location: 0.0),
                                                    .init(color: .blue, location: 0.25),
                                                    .init(color: .purple, location: 0.5),
                                                    .init(color: .blue, location: 0.75),
                                                    .init(color: .green, location: 1.0),
                                                ]),
                                                center: .center
                                            )
                                        )
                                        .blur(radius: 4)
                                        .opacity(0.8)

                                    // Glass overlay
                                    Circle()
                                        .fill(Color(UIColor.systemBackground).opacity(0.3))
                                        .blur(radius: 0.5)
                                }
                            )
                    }
                    .frame(height: contentHeight) // Match the height of the input field
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

    // Update the content height based on text
    private func updateHeight(for text: String) {
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

        // For height calculation, we limit to maxLines
        // But we don't limit the actual text - it will scroll
        let visibleLineCount = min(estimatedLineCount, maxLines)

        // Calculate height based on visible line count
        let calculatedHeight = minHeight + (lineHeight * CGFloat(visibleLineCount - 1))

        // Apply min/max constraints with some padding
        contentHeight = max(minHeight, min(calculatedHeight + 16, maxHeight))

        // Debug info
        print("Text length: \(text.count), Total lines: \(estimatedLineCount), Visible lines: \(visibleLineCount), Height: \(contentHeight)")
    }

    // MARK: - Animation Functions

    private func startRotationTimer() {
        // Stop any existing timer first
        stopRotationTimer()

        // Reset rotation to 0
        gradientRotation = 0

        // Create a new timer that updates the rotation angle
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [self] _ in
            // Update rotation on the main thread
            DispatchQueue.main.async {
                // Increment rotation by 3 degrees each time for faster rotation
                withAnimation(.linear(duration: 0.02)) {
                    self.gradientRotation = (self.gradientRotation + 3).truncatingRemainder(dividingBy: 360)
                }
            }
        }
    }

    private func stopRotationTimer() {
        rotationTimer?.invalidate()
        rotationTimer = nil
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

        // Multiline state (2 lines)
        ThreadInputBar(
            input: .constant("This is a multiline message.\nIt has two lines of text to demonstrate how the input bar grows."),
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
            input: .constant("This is a message being processed with multiple lines.\nShowing how it looks during processing."),
            isProcessing: true,
            onSend: { _ in },
            onCancel: {},
            processingStatus: "Processing multiline input...",
            isProcessingLargeInput: true
        )
        .padding(.bottom, 20)

        // Large input warning state
        ThreadInputBar(
            input: .constant("This is a very large message that would trigger the warning. It also has multiple lines to show how the warning appears with a taller input field.\nThis is the second line of the message."),
            isProcessing: false,
            onSend: { _ in },
            onCancel: {},
            isProcessingLargeInput: false
        )
        .environment(\.colorScheme, .dark) // Show in dark mode for contrast
    }
    .background(Color(UIColor.systemBackground))
    .padding(.vertical)
}
