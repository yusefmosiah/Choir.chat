import Foundation
import SwiftUI
// Removed UIKit import
import CoreText

/// A class that handles pagination of markdown content using accurate text measurement.
class MarkdownPaginator {

    /// Paginates markdown content using Core Text for accurate measurement.
    /// - Parameters:
    ///   - text: The markdown text to paginate.
    ///   - width: The available width for each page.
    ///   - height: The available height for each page.
    /// - Returns: An array of strings, each representing a page of content.
    func paginateMarkdown(_ text: String, width: CGFloat, height: CGFloat) -> [String] {
        guard !text.isEmpty, width > 0, height > 0 else {
            print("[MarkdownPaginator] Input text is empty or dimensions are invalid. Returning single page.")
            return [text] // Return original text if empty or dimensions invalid
        }

        var pages: [String] = []
        var currentStartIndex = text.startIndex

        // Prepare the full attributed string (minimal attributes for measurement)
        // Core Text will use default font/paragraph styles if not specified.
        // The goal is layout fitting, not perfect style matching here.
        let baseAttributes: [NSAttributedString.Key: Any] = [
             .paragraphStyle: NSParagraphStyle.default // Keep paragraph style for basic line breaking
        ]
        // Create NSAttributedString without explicit font
        let fullAttributedString = NSAttributedString(string: text, attributes: baseAttributes)


        print("[MarkdownPaginator] Starting pagination for text length \(text.count) with size W:\(width) H:\(height)")

        while currentStartIndex < text.endIndex {
            let remainingRange = NSRange(currentStartIndex..<text.endIndex, in: text)
            if remainingRange.length == 0 { break } // Should not happen if loop condition is correct, but safety check

            let remainingAttributedString = fullAttributedString.attributedSubstring(from: remainingRange)

            // Create a CTFramesetter
            let framesetter = CTFramesetterCreateWithAttributedString(remainingAttributedString as CFAttributedString)

            // Define the frame path (available area)
            let framePath = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: height), transform: nil)

            // Create a frame to see how much text fits
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, nil)

            // Get the range of characters that fit in this frame
            let visibleRange = CTFrameGetVisibleStringRange(frame)

            if visibleRange.length == 0 {
                // If absolutely nothing fits (e.g., extremely small height),
                // we must consume *something* to avoid an infinite loop.
                // Take the first character or line. This is an edge case.
                print("[MarkdownPaginator] Warning: Zero characters fit in the frame. Consuming first character/line.")
                let nextNewline = text[currentStartIndex...].firstIndex(of: "\n")
                let endIndex: String.Index
                if let nextNewline = nextNewline, nextNewline > currentStartIndex {
                    endIndex = text.index(after: nextNewline) // Include newline
                } else {
                    endIndex = text.index(currentStartIndex, offsetBy: 1, limitedBy: text.endIndex) ?? text.endIndex
                }
                let pageText = String(text[currentStartIndex..<endIndex])
                if !pageText.isEmpty {
                    pages.append(pageText)
                }
                currentStartIndex = endIndex
                continue // Move to the next iteration
            }

            // Calculate the end index in the original string
            guard let pageEndIndex = text.index(currentStartIndex, offsetBy: visibleRange.length, limitedBy: text.endIndex) else {
                 print("[MarkdownPaginator] Error: Could not calculate pageEndIndex. Aborting pagination.")
                 // If we can't calculate the end index, something is wrong. Return what we have.
                 if pages.isEmpty { pages.append(text) } // Avoid returning empty if text was present
                 return pages
            }


            // Extract the text for the current page
            let pageText = String(text[currentStartIndex..<pageEndIndex])
            pages.append(pageText)
            print("[MarkdownPaginator] Added page \(pages.count) with \(pageText.count) characters (Range: \(visibleRange.location)-\(visibleRange.location + visibleRange.length))")


            // Update the start index for the next iteration
            currentStartIndex = pageEndIndex
        }

        print("[MarkdownPaginator] Pagination complete: \(pages.count) pages created.")
        // Ensure at least one page is returned if the original text was not empty
        if pages.isEmpty && !text.isEmpty {
            print("[MarkdownPaginator] Pagination resulted in zero pages for non-empty text. Returning original text as single page.")
            return [text]
        } else if pages.isEmpty && text.isEmpty {
             return [""] // Return one empty page for empty input
        }


        return pages
    }

    // Note: Context preservation logic (analyzeContextAtSplitPoint, continuationPrefix)
    // is removed as Core Text measurement handles layout directly. If specific markdown
    // block continuation (like list numbers, code block fences) is needed across
    // Core Text frames, it would require significantly more complex logic involving
    // parsing the markdown structure alongside measurement, which is beyond the scope
    // of this refactor focused on accurate splitting. The current approach ensures
    // all text is included, split accurately by visual height.
}

// TextMeasurer class is no longer needed by MarkdownPaginator and can be removed
// if it's not used elsewhere. For now, we leave it commented out or remove it later.
/*
/// A helper class to measure text height
class TextMeasurer {
    // ... (Keep implementation if used elsewhere, otherwise remove)
}
*/
