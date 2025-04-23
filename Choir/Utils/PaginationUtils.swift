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

    // Track the current vector ID being fetched to prevent duplicate API calls
    private var currentVectorId: String? = nil
    private var isProcessingVectorRequest = false

    func showSheet(withText text: String) {
        self.selectedText = text
        self.phaseContentSelection = nil
        self.showingSheet = true
        self.preventBackgroundUpdates = true
    }

    // Show sheet for vector content with duplicate prevention
    func showVectorSheet(withText text: String, vectorId: String) {
        // If we're already processing this vector ID, just update the text
        if isProcessingVectorRequest && currentVectorId == vectorId {
            // Add a small delay to ensure the sheet is fully presented
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.selectedText = text
            }
            return
        }

        // If we're already showing a sheet for a different vector, dismiss it first
        if isProcessingVectorRequest && currentVectorId != vectorId && showingSheet {
            // Dismiss the current sheet
            self.showingSheet = false

            // Wait a moment for the dismissal animation, then show the new sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }

                // Set the current vector ID and mark as processing
                self.currentVectorId = vectorId
                self.isProcessingVectorRequest = true

                // Show the sheet
                self.selectedText = text
                self.phaseContentSelection = nil
                self.showingSheet = true
                self.preventBackgroundUpdates = true
            }
            return
        }

        // Set the current vector ID and mark as processing
        currentVectorId = vectorId
        isProcessingVectorRequest = true

        // Show the sheet
        self.selectedText = text
        self.phaseContentSelection = nil
        self.showingSheet = true
        self.preventBackgroundUpdates = true
    }

    // Update the content of an already displayed vector sheet
    func updateVectorSheet(withText text: String, vectorId: String) {
        // Only update if we're already showing this vector
        if isProcessingVectorRequest && currentVectorId == vectorId && showingSheet {
            // Add a small delay to ensure the sheet is fully presented
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.selectedText = text
            }
        }
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

        // Reset vector request tracking
        self.currentVectorId = nil
        self.isProcessingVectorRequest = false
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

        // Process the text to find link boundaries
        let linkRanges = findLinkRanges(in: text)

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

        // Get the initial fitting text length
        var length = characterRange.length

        // Adjust length to avoid breaking links
        if !linkRanges.isEmpty && !text.isEmpty {
            let textStartIndex = text.startIndex

            for range in linkRanges {
                // Convert String.Index values to integer offsets for comparison
                let rangeStart = text.distance(from: textStartIndex, to: range.lowerBound)
                let rangeEnd = text.distance(from: textStartIndex, to: range.upperBound)

                // If a link is partially included, either include it fully or exclude it
                if rangeStart < length && rangeEnd > length {
                    // If more than half of the link is included, include the whole link
                    let linkLength = rangeEnd - rangeStart
                    if (length - rangeStart) > (linkLength / 2) {
                        length = rangeEnd
                    } else {
                        // Otherwise, exclude the link entirely
                        length = rangeStart
                    }
                }
            }
        }

        // Make sure we don't exceed the text length
        length = min(length, text.count)

        let fittingText = text.prefix(length)
        return String(fittingText)
    }

    // Helper function to find markdown link ranges in text
    private func findLinkRanges(in text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []

        // Find markdown links [text](url)
        let linkPattern = "\\[([^\\[\\]]*)\\]\\(([^\\(\\)]*)\\)"
        if let regex = try? NSRegularExpression(pattern: linkPattern, options: []) {
            let nsString = NSString(string: text)
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                if let range = Range(match.range, in: text) {
                    ranges.append(range)
                }
            }
        }

        // Find <vid> tags
        let vidPattern = "<vid>([^<>]+)</vid>"
        if let regex = try? NSRegularExpression(pattern: vidPattern, options: []) {
            let nsString = NSString(string: text)
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                if let range = Range(match.range, in: text) {
                    ranges.append(range)
                }
            }
        }

        return ranges
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
