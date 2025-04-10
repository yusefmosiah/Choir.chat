import SwiftUI

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
                    TextSelectionView(text: textSelectionManager.selectedText)
                        .background(.ultraThinMaterial)
                }
        }
    }
}

struct TextSelectionView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var textSelectionManager = TextSelectionManager.shared

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color(UIColor.systemBackground)
                        .opacity(0.85)
                        .edgesIgnoringSafeArea(.all)

                    TextViewWrapper(text: text)
                        .frame(width: geometry.size.width, height: geometry.size.height)
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
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
            uiView.layoutIfNeeded()
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
