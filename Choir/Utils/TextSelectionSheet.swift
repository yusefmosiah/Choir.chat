import SwiftUI
import UIKit

struct TextSelectionSheetProvider<Content: View>: View {
    @StateObject private var textSelectionManager = TextSelectionManager.shared
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content

            Color.clear
                .frame(width: 0, height: 0)
                .sheet(isPresented: $textSelectionManager.showingSheet, onDismiss: {
                    textSelectionManager.sheetDismissed()
                }) {
                    if let selection = textSelectionManager.phaseContentSelection {
                        TextSelectionView(
                            text: selection.fullContent,
                            selectedRange: selection.currentPageRange
                        )
                        .background(.ultraThinMaterial)
                    } else {
                        TextSelectionView(text: textSelectionManager.selectedText, selectedRange: nil)
                            .background(.ultraThinMaterial)
                    }
                }
        }
    }
}

struct TextSelectionView: View {
    let text: String
    let selectedRange: NSRange?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var textSelectionManager = TextSelectionManager.shared

    // Format reward amount from raw value
    private func formattedRewardAmount(_ amount: Int) -> String {
        let choirAmount = Double(amount) / 1_000_000_000.0
        return String(format: "%.2f", choirAmount)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Citation information section
                if let explanation = textSelectionManager.citationExplanation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Citation Information")
                            .font(.headline)
                            .padding(.bottom, 4)

                        Text(explanation)
                            .font(.body)

                        if let reward = textSelectionManager.citationReward,
                           let amount = reward["reward_amount"] as? Int,
                           let success = reward["success"] as? Bool,
                           success {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("This citation earned the author \(formattedRewardAmount(amount)) CHOIR tokens")
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top)
                }

                // Main content
                GeometryReader { geometry in
                    ZStack {
                        Color(UIColor.systemBackground)
                            .opacity(0.85)
                            .edgesIgnoringSafeArea(.all)

                        TextViewWrapper(text: text, selectedRange: selectedRange)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
            }
            .navigationTitle("Select Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        textSelectionManager.sheetDismissed()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Copy") {
                        UIPasteboard.general.string = UIPasteboard.general.string ?? text
                        textSelectionManager.sheetDismissed()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(true)
        .onDisappear {
            textSelectionManager.sheetDismissed()
        }
    }
}

struct TextViewWrapper: UIViewRepresentable {
    let text: String
    let selectedRange: NSRange?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.dataDetectorTypes = .link
        textView.delegate = context.coordinator
        textView.isOpaque = false
        textView.text = text
        textView.layoutIfNeeded()

        if let selectedRange = selectedRange {
            DispatchQueue.main.async {
                textView.selectedRange = selectedRange
                textView.scrollRangeToVisible(selectedRange)
            }
        }

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            // Save scroll position if possible
            let contentOffset = uiView.contentOffset
            let visibleHeight = uiView.bounds.height

            // Update text
            uiView.text = text
            uiView.layoutIfNeeded()

            if let selectedRange = selectedRange {
                DispatchQueue.main.async {
                    uiView.selectedRange = selectedRange
                    uiView.scrollRangeToVisible(selectedRange)
                }
            } else {
                // Try to maintain scroll position for content updates
                DispatchQueue.main.async {
                    // If the content is similar (like when updating vector content),
                    // try to maintain the scroll position
                    if text.hasPrefix("# Vector Result") && uiView.contentSize.height > visibleHeight {
                        uiView.contentOffset = contentOffset
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextViewWrapper

        init(_ parent: TextViewWrapper) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            // Future use
        }
    }
}
