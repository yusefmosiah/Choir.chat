import SwiftUI

class TextSelectionManager: ObservableObject {
    static let shared = TextSelectionManager()

    @Published var showingSheet = false
    @Published var selectedText = ""
    @Published var activeText: String? = nil
    @Published var isShowingMenu = false
    @Published var isInteractionDisabled = false
    @Published var preventBackgroundUpdates = false

    func showSheet(withText text: String) {
        self.selectedText = text
        self.showingSheet = true
        self.preventBackgroundUpdates = true
    }

    func setActiveText(_ text: String) {
        self.activeText = text
        self.isShowingMenu = true
    }

    func clearActiveText() {
        self.activeText = nil
        self.isShowingMenu = false
    }

    func sheetDismissed() {
        self.showingSheet = false
        self.preventBackgroundUpdates = false
    }

    func temporarilyDisableInteractions() {
        if preventBackgroundUpdates { return }
        isInteractionDisabled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isInteractionDisabled = false
        }
    }
}

class TextMeasurer {
    let sizeCategory: ContentSizeCategory

    init(sizeCategory: ContentSizeCategory) {
        self.sizeCategory = sizeCategory
    }

    private var font: UIFont {
        let style = UIFont.TextStyle.body
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        return UIFont(descriptor: descriptor, size: 0)
    }

    func fitTextToHeight(text: String, width: CGFloat, height: CGFloat) -> String {
        if text.isEmpty { return "" }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = 4

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        let attributedText = NSAttributedString(string: text, attributes: attributes)

        let textContainer = NSTextContainer(size: CGSize(width: width, height: height))
        textContainer.lineFragmentPadding = 0

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)

        let textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addLayoutManager(layoutManager)

        let glyphRange = layoutManager.glyphRange(for: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        let fittingText = text.prefix(characterRange.length)

        return String(fittingText)
    }
}
