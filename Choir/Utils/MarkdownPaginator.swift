import Foundation
import SwiftUI
import UIKit

/// A class that handles pagination of markdown content using efficient text measurement.
class MarkdownPaginator {
    // Minimum content threshold - don't create pages with less than this amount of content
    private let minContentThreshold: Int = 20

    // Minimum page fill threshold - if a page is less than this percentage full,
    // try to pull content from the next page
    private let minPageFillThreshold: CGFloat = 0.6

    // Target page fill threshold - aim to fill pages to this percentage
    private let targetPageFillThreshold: CGFloat = 0.8

    // Maximum page fill threshold - absolute maximum to prevent overflow
    private let maxPageFillThreshold: CGFloat = 0.95

    // Safety margin - percentage of height to reserve as safety margin
    private let safetyMargin: CGFloat = 0.05

    /// Paginates markdown content using a sentence-aware approach.
    /// - Parameters:
    ///   - text: The markdown text to paginate.
    ///   - width: The available width for each page.
    ///   - height: The available height for each page.
    ///   - font: The base font to use for measurement (considers accessibility).
    /// - Returns: An array of strings, each representing a page of content.
    func paginateMarkdown(_ text: String, width: CGFloat, height: CGFloat, font: UIFont = UIFont.preferredFont(forTextStyle: .body)) -> [String] {
        guard !text.isEmpty, width > 0, height > 0 else {
            return [text.isEmpty ? "" : text] // Return [""] for empty input, [text] otherwise
        }

        // Split text into semantic units (paragraphs, sentences)
        let textUnits = splitIntoSemanticUnits(text)

        // Create pages by combining units
        return createPagesFromUnits(textUnits, width: width, height: height, font: font)
    }

    /// Splits text into semantic units (paragraphs, sentences) that should be kept together
    private func splitIntoSemanticUnits(_ text: String) -> [String] {
        var units: [String] = []

        // First split by paragraphs (double newlines)
        let paragraphs = text.components(separatedBy: "\n\n")

        for paragraph in paragraphs {
            if paragraph.isEmpty { continue }

            // For each paragraph, split by sentences if it's a long paragraph
            if paragraph.count > 200 {
                // Use regex to split by sentence endings (., !, ?) followed by space or newline
                let sentencePattern = "(?<=[.!?])\\s+"
                if let regex = try? NSRegularExpression(pattern: sentencePattern) {
                    let nsString = paragraph as NSString
                    let matches = regex.matches(in: paragraph, range: NSRange(location: 0, length: nsString.length))

                    var lastIndex = 0
                    for match in matches {
                        let range = match.range
                        let sentence = nsString.substring(with: NSRange(location: lastIndex, length: range.location - lastIndex))
                        if !sentence.isEmpty {
                            units.append(sentence)
                        }
                        lastIndex = range.location + range.length
                    }

                    // Add the last sentence
                    if lastIndex < nsString.length {
                        let lastSentence = nsString.substring(from: lastIndex)
                        if !lastSentence.isEmpty {
                            units.append(lastSentence)
                        }
                    }
                } else {
                    // Fallback if regex fails
                    units.append(paragraph)
                }
            } else {
                // For shorter paragraphs, keep them as a single unit
                units.append(paragraph)
            }
        }

        // Ensure we don't have empty units
        return units.filter { !$0.isEmpty }
    }

    /// Creates pages by combining semantic units
    private func createPagesFromUnits(_ units: [String], width: CGFloat, height: CGFloat, font: UIFont) -> [String] {
        var pages: [String] = []
        var currentPage = ""
        var currentPageHeight: CGFloat = 0

        // Create measurement resources
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = font.pointSize * 0.2

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        for (index, unit) in units.enumerated() {
            // Measure this unit
            let unitText = index > 0 && !currentPage.isEmpty ? "\n\n" + unit : unit
            let unitHeight = measureTextHeight(unitText, width: width, attributes: baseAttributes)

            // Check if adding this unit would exceed the page height
            let projectedHeight = currentPageHeight + unitHeight
            let effectiveMaxHeight = height * (maxPageFillThreshold - safetyMargin)

            // If the page is empty, we must add at least one unit regardless of size
            if currentPage.isEmpty {
                currentPage = unit
                currentPageHeight = unitHeight
            }
            // If adding this unit would still keep us under our target fill threshold, add it
            else if projectedHeight <= effectiveMaxHeight {
                // Add the unit with proper spacing
                currentPage += "\n\n" + unit
                currentPageHeight = projectedHeight

                // If we're now above our target fill threshold, start a new page for the next unit
                if currentPageHeight >= height * targetPageFillThreshold && index < units.count - 1 {
                    pages.append(currentPage)
                    currentPage = ""
                    currentPageHeight = 0
                }
            }
            // Unit doesn't fit within our max threshold, start a new page
            else {
                // Only start a new page if the current one has content
                if !currentPage.isEmpty {
                    pages.append(currentPage)
                }
                currentPage = unit
                currentPageHeight = unitHeight
            }
        }

        // Add the last page if not empty
        if !currentPage.isEmpty {
            pages.append(currentPage)
        }

        // Post-process pages to ensure no tiny fragments
        return balancePages(pages, width: width, height: height, font: font)
    }

    /// Balances pages to ensure better content distribution and no tiny fragments
    private func balancePages(_ initialPages: [String], width: CGFloat, height: CGFloat, font: UIFont) -> [String] {
        guard initialPages.count > 1 else {
            return initialPages
        }

        var balancedPages: [String] = []
        var currentPage = ""
        var currentPageHeight: CGFloat = 0

        // Create measurement resources
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = font.pointSize * 0.2

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        // First pass: combine very small pages with the previous page
        for (index, page) in initialPages.enumerated() {
            let pageHeight = measureTextHeight(page, width: width, attributes: baseAttributes)
            let pageFillRatio = pageHeight / height

            // If this is a small page (less than 30% full) and not the first page,
            // try to combine it with the previous page
            if pageFillRatio < 0.3 && index > 0 && !page.isEmpty {
                let prevPage = balancedPages.last ?? ""
                let combinedPage = prevPage + (prevPage.isEmpty ? "" : "\n\n") + page
                let combinedHeight = measureTextHeight(combinedPage, width: width, attributes: baseAttributes)
                let effectiveMaxHeight = height * (maxPageFillThreshold - safetyMargin)

                if combinedHeight <= effectiveMaxHeight {
                    // It fits! Replace the previous page with the combined page
                    if !balancedPages.isEmpty {
                        balancedPages.removeLast()
                    }
                    balancedPages.append(combinedPage)
                } else {
                    // Doesn't fit, add as a separate page
                    balancedPages.append(page)
                }
            } else {
                // Normal sized page, add it
                balancedPages.append(page)
            }
        }

        // Second pass: check for underfilled pages and try to pull content from the next page
        var finalPages: [String] = []
        var i = 0

        while i < balancedPages.count {
            let page = balancedPages[i]

            // If this is the last page, just add it
            if i == balancedPages.count - 1 {
                finalPages.append(page)
                break
            }

            // Check how full the current page is
            let pageHeight = measureTextHeight(page, width: width, attributes: baseAttributes)
            let pageFillRatio = pageHeight / height

            // If the page is underfilled and there's another page, try to pull content
            if pageFillRatio < minPageFillThreshold {
                let nextPage = balancedPages[i + 1]

                // Try to find a good break point by splitting the next page into sentences
                let nextPageUnits = splitIntoSemanticUnits(nextPage)

                if !nextPageUnits.isEmpty {
                    var bestCombinedPage = page
                    var bestRemainingPage = nextPage
                    var bestCombinedHeight = pageHeight
                    var bestFillRatio = pageFillRatio

                    // Try adding units from the next page one by one
                    var combinedPage = page
                    var remainingUnits = nextPageUnits
                    let effectiveMaxHeight = height * (maxPageFillThreshold - safetyMargin)

                    for j in 0..<nextPageUnits.count {
                        let unitToAdd = nextPageUnits[j]
                        let separator = combinedPage.isEmpty ? "" : "\n\n"
                        let newCombinedPage = combinedPage + separator + unitToAdd

                        let newCombinedHeight = measureTextHeight(newCombinedPage, width: width, attributes: baseAttributes)
                        let newFillRatio = newCombinedHeight / height

                        if newCombinedHeight <= effectiveMaxHeight {
                            // It fits! Update the combined page
                            combinedPage = newCombinedPage
                            remainingUnits.removeFirst()

                            // Update the best combination if this is better
                            // We prefer combinations that get us closer to our target fill ratio
                            if newFillRatio <= targetPageFillThreshold && newFillRatio > bestFillRatio {
                                bestCombinedPage = newCombinedPage
                                bestCombinedHeight = newCombinedHeight
                                bestFillRatio = newFillRatio
                                bestRemainingPage = remainingUnits.joined(separator: "\n\n")
                            }

                            // If we've reached our target fill threshold, we can stop
                            if newFillRatio >= targetPageFillThreshold {
                                break
                            }
                        } else {
                            // Doesn't fit anymore, stop adding
                            break
                        }
                    }

                    // Use the best combination we found
                    finalPages.append(bestCombinedPage)

                    // If we used all of the next page, skip it
                    if bestRemainingPage.isEmpty {
                        i += 2
                    } else {
                        // Otherwise, update the next page with the remaining content
                        balancedPages[i + 1] = bestRemainingPage
                        i += 1
                    }
                } else {
                    // Next page couldn't be split, just add the current page
                    finalPages.append(page)
                    i += 1
                }
            } else {
                // Page is reasonably full, add it as is
                finalPages.append(page)
                i += 1
            }
        }

        // Final check: ensure no tiny fragments at the end and try to balance the last pages
        if finalPages.count > 1 {
            let lastPage = finalPages.last ?? ""
            let lastPageHeight = measureTextHeight(lastPage, width: width, attributes: baseAttributes)
            let lastPageFillRatio = lastPageHeight / height
            let effectiveMaxHeight = height * (maxPageFillThreshold - safetyMargin)

            // If the last page is small (less than 40% full), try to combine with previous page
            if lastPageFillRatio < 0.4 {
                let prevPage = finalPages[finalPages.count - 2]
                let prevPageHeight = measureTextHeight(prevPage, width: width, attributes: baseAttributes)
                let prevPageFillRatio = prevPageHeight / height

                // Only try to combine if the previous page isn't already very full
                if prevPageFillRatio < targetPageFillThreshold {
                    let combinedPage = prevPage + (prevPage.isEmpty ? "" : "\n\n") + lastPage
                    let combinedHeight = measureTextHeight(combinedPage, width: width, attributes: baseAttributes)

                    if combinedHeight <= effectiveMaxHeight {
                        // It fits! Replace the last two pages with the combined page
                        finalPages.removeLast(2)
                        finalPages.append(combinedPage)
                    }
                }
            }

            // If we still have a very tiny last page, make one more attempt with a higher threshold
            if finalPages.count > 1 {
                let lastPage = finalPages.last ?? ""
                let lastPageHeight = measureTextHeight(lastPage, width: width, attributes: baseAttributes)

                if lastPageHeight < height * 0.2 && lastPage.count < minContentThreshold {
                    let prevPage = finalPages[finalPages.count - 2]
                    let combinedPage = prevPage + (prevPage.isEmpty ? "" : "\n\n") + lastPage
                    let combinedHeight = measureTextHeight(combinedPage, width: width, attributes: baseAttributes)

                    // Use a higher threshold for tiny fragments
                    if combinedHeight <= height * maxPageFillThreshold {
                        finalPages.removeLast(2)
                        finalPages.append(combinedPage)
                    }
                }
            }
        }

        return finalPages
    }

    /// Measures the height of text when rendered with the given width and attributes
    private func measureTextHeight(_ text: String, width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textStorage = NSTextStorage(attributedString: attributedString)
        let textContainer = NSTextContainer(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        layoutManager.glyphRange(for: textContainer) // Force layout

        return layoutManager.usedRect(for: textContainer).height
    }
}
