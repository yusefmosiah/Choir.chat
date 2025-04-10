import SwiftUI
import UIKit

struct PhaseContentSelection {
    let fullContent: String
    let currentPageRange: NSRange
}

class TextSelectionManager: ObservableObject {
    static let shared = TextSelectionManager()

    @Published var showingSheet = false
    @Published var selectedText = ""
    @Published var activeText: String? = nil
    @Published var isShowingMenu = false
    @Published var isInteractionDisabled = false
    @Published var preventBackgroundUpdates = false
    @Published var phaseContentSelection: PhaseContentSelection? = nil

    func showSheet(withText text: String) {
        self.selectedText = text
        self.phaseContentSelection = nil
        self.showingSheet = true
        self.preventBackgroundUpdates = true
    }

    func showSheet(withPhaseContent content: String, currentPageRange: NSRange) {
        self.phaseContentSelection = PhaseContentSelection(
            fullContent: content,
            currentPageRange: currentPageRange
        )
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

    func splitMarkdownIntoPages(_ text: String, size: CGSize) -> [String] {
        let textHeight = size.height - 40
        var pages: [String] = []
        var remainingText = text

        while !remainingText.isEmpty {
            let pageText = fitTextToHeight(
                text: remainingText,
                width: size.width - 8,
                height: textHeight
            )
            pages.append(pageText)

            if pageText.count < remainingText.count {
                let index = remainingText.index(remainingText.startIndex, offsetBy: pageText.count)
                remainingText = String(remainingText[index...])
            } else {
                remainingText = ""
            }
        }
        return pages
    }
}
