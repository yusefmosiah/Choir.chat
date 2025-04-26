import Foundation
import SwiftUI
import UIKit

// Extension to help with pattern matching in strings
extension String {
    func matches(pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

/// A class that handles pagination of markdown content using efficient text measurement.
class MarkdownPaginator {
    // Minimum content threshold - don't create pages with less than this amount of content
    private let minContentThreshold: Int = 20

    // Minimum page fill threshold - if a page is less than this percentage full,
    // try to pull content from the next page
    private let minPageFillThreshold: CGFloat = 0.7

    // Target page fill threshold - aim to fill pages to this percentage
    private let targetPageFillThreshold: CGFloat = 0.8

    // Maximum page fill threshold - absolute maximum to prevent overflow
    private let maxPageFillThreshold: CGFloat = 0.95

    // Safety margin - percentage of height to reserve as safety margin
    private let safetyMargin: CGFloat = 0.03

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

        // First identify and preserve list items
        let processedText = preprocessListItems(text)

        // Then split by paragraphs (double newlines)
        let paragraphs = processedText.components(separatedBy: "\n\n")

        for paragraph in paragraphs {
            if paragraph.isEmpty { continue }

            // Check if this is a list item (starts with number or bullet)
            let trimmedParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            let isListItem = trimmedParagraph.matches(pattern: "^\\s*[0-9]+\\.\\s+.*") ||
                             trimmedParagraph.matches(pattern: "^\\s*[•\\-\\*]\\s+.*")

            // Always keep list items as a single unit
            if isListItem {
                units.append(paragraph)
                continue
            }

            // For each paragraph, split by sentences if it's a long paragraph
            if paragraph.count > 200 && !isListItem {
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

    /// Preprocesses the text to ensure list items stay together
    private func preprocessListItems(_ text: String) -> String {
        // Split the text into lines
        var lines = text.components(separatedBy: .newlines)
        var processedLines: [String] = []
        var currentListItem: String = ""
        var inList = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if this line is a list item (starts with number or bullet)
            let isListItem = trimmedLine.matches(pattern: "^\\s*[0-9]+\\.\\s+.*") ||
                             trimmedLine.matches(pattern: "^\\s*[•\\-\\*]\\s+.*")

            if isListItem {
                // If we were already building a list item, add it to processed lines
                if !currentListItem.isEmpty {
                    processedLines.append(currentListItem)
                }

                // Start a new list item
                currentListItem = line
                inList = true
            } else if inList && !trimmedLine.isEmpty {
                // This is a continuation of the current list item
                currentListItem += "\n" + line
            } else {
                // Not a list item or continuation
                if !currentListItem.isEmpty {
                    processedLines.append(currentListItem)
                    currentListItem = ""
                }
                inList = false
                processedLines.append(line)
            }
        }

        // Add the last list item if there is one
        if !currentListItem.isEmpty {
            processedLines.append(currentListItem)
        }

        return processedLines.joined(separator: "\n")
    }

    /// Creates pages by combining semantic units
    private func createPagesFromUnits(_ units: [String], width: CGFloat, height: CGFloat, font: UIFont) -> [String] {
        var pages: [String] = []
        var currentPage = ""
        var currentPageHeight: CGFloat = 0

        // Create measurement resources
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = font.pointSize * 0.15 // Reduced line spacing
        paragraphStyle.paragraphSpacing = font.pointSize * 0.3 // Control spacing between paragraphs
        paragraphStyle.headIndent = 0 // Minimize indentation for lists
        paragraphStyle.firstLineHeadIndent = 0 // Minimize first line indentation

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        // First, measure all units to better plan page breaks
        var unitMeasurements: [(unit: String, height: CGFloat)] = []
        for unit in units {
            let unitHeight = measureTextHeight(unit, width: width, attributes: baseAttributes)
            unitMeasurements.append((unit: unit, height: unitHeight))
        }

        // Calculate ideal page fill height
        let idealPageFillHeight = height * targetPageFillThreshold
        let maxPageFillHeight = height * (maxPageFillThreshold - safetyMargin)

        for (index, measurement) in unitMeasurements.enumerated() {
            let unit = measurement.unit
            let unitHeight = measurement.height

            // Calculate projected height if we add this unit
            let separator = currentPage.isEmpty ? "" : "\n\n"
            let projectedHeight = currentPageHeight + (currentPage.isEmpty ? 0 : measureTextHeight(separator, width: width, attributes: baseAttributes)) + unitHeight

            // If the page is empty, we must add at least one unit regardless of size
            if currentPage.isEmpty {
                currentPage = unit
                currentPageHeight = unitHeight

                // Special case: if this single unit is already very large (over 85% of page),
                // and it's not the only unit, consider splitting it further
                if unitHeight > height * 0.85 && units.count > 1 {
                    // Try to split this large unit into smaller pieces
                    let subunits = splitLargeUnit(unit)
                    if subunits.count > 1 {
                        // Replace this unit with its first subunit
                        currentPage = subunits[0]
                        currentPageHeight = measureTextHeight(subunits[0], width: width, attributes: baseAttributes)

                        // Add remaining subunits back to the beginning of our processing queue
                        var remainingUnits = Array(unitMeasurements[(index+1)...])
                        for i in 1..<subunits.count {
                            let subunitHeight = measureTextHeight(subunits[i], width: width, attributes: baseAttributes)
                            remainingUnits.insert((unit: subunits[i], height: subunitHeight), at: i-1)
                        }

                        // Continue with the updated queue
                        unitMeasurements = Array(unitMeasurements[0..<index]) + remainingUnits
                    }
                }
            }
            // If adding this unit would still keep us under our max fill threshold, add it
            else if projectedHeight <= maxPageFillHeight {
                // Add the unit with proper spacing
                currentPage += "\n\n" + unit
                currentPageHeight = projectedHeight

                // If we're now above our target fill threshold, start a new page for the next unit
                if currentPageHeight >= idealPageFillHeight && index < unitMeasurements.count - 1 {
                    // Check if adding one more small unit would make a better page
                    if index + 1 < unitMeasurements.count {
                        let nextUnit = unitMeasurements[index + 1]
                        let nextProjectedHeight = currentPageHeight + measureTextHeight("\n\n", width: width, attributes: baseAttributes) + nextUnit.height

                        // If adding the next unit still keeps us under max and closer to ideal, add it too
                        if nextProjectedHeight <= maxPageFillHeight &&
                           abs(nextProjectedHeight - idealPageFillHeight) < abs(currentPageHeight - idealPageFillHeight) {
                            // Skip this page break, we'll add the next unit too
                            continue
                        }
                    }

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

                // If this unit alone is too big for a page, try to split it
                if unitHeight > maxPageFillHeight {
                    let subunits = splitLargeUnit(unit)
                    if subunits.count > 1 {
                        // Use first subunit for current page
                        currentPage = subunits[0]
                        currentPageHeight = measureTextHeight(subunits[0], width: width, attributes: baseAttributes)

                        // Add remaining subunits back to the beginning of our processing queue
                        var remainingUnits = Array(unitMeasurements[(index+1)...])
                        for i in 1..<subunits.count {
                            let subunitHeight = measureTextHeight(subunits[i], width: width, attributes: baseAttributes)
                            remainingUnits.insert((unit: subunits[i], height: subunitHeight), at: i-1)
                        }

                        // Continue with the updated queue
                        unitMeasurements = Array(unitMeasurements[0..<index]) + remainingUnits
                    } else {
                        // Can't split further, use as is
                        currentPage = unit
                        currentPageHeight = unitHeight
                    }
                } else {
                    // Normal sized unit, start a new page with it
                    currentPage = unit
                    currentPageHeight = unitHeight
                }
            }
        }

        // Add the last page if not empty
        if !currentPage.isEmpty {
            pages.append(currentPage)
        }

        // Post-process pages to ensure no tiny fragments
        return balancePages(pages, width: width, height: height, font: font)
    }

    /// Attempts to split a large unit into smaller pieces
    private func splitLargeUnit(_ unit: String) -> [String] {
        // If this is a list item, don't split it
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let isListItem = trimmedUnit.matches(pattern: "^\\s*[0-9]+\\.\\s+.*") ||
                         trimmedUnit.matches(pattern: "^\\s*[•\\-\\*]\\s+.*")

        if isListItem {
            return [unit]
        }

        // Try to split by sentences
        let sentencePattern = "(?<=[.!?])\\s+"
        if let regex = try? NSRegularExpression(pattern: sentencePattern) {
            let nsString = unit as NSString
            let matches = regex.matches(in: unit, range: NSRange(location: 0, length: nsString.length))

            if matches.count > 1 {
                var sentences: [String] = []
                var lastIndex = 0

                for match in matches {
                    let range = match.range
                    let sentence = nsString.substring(with: NSRange(location: lastIndex, length: range.location - lastIndex))
                    if !sentence.isEmpty {
                        sentences.append(sentence)
                    }
                    lastIndex = range.location + range.length
                }

                // Add the last sentence
                if lastIndex < nsString.length {
                    let lastSentence = nsString.substring(from: lastIndex)
                    if !lastSentence.isEmpty {
                        sentences.append(lastSentence)
                    }
                }

                // Group sentences into reasonable chunks
                if sentences.count > 1 {
                    var chunks: [String] = []
                    var currentChunk = ""

                    for sentence in sentences {
                        if currentChunk.isEmpty {
                            currentChunk = sentence
                        } else if currentChunk.count + sentence.count < 500 {
                            currentChunk += " " + sentence
                        } else {
                            chunks.append(currentChunk)
                            currentChunk = sentence
                        }
                    }

                    if !currentChunk.isEmpty {
                        chunks.append(currentChunk)
                    }

                    return chunks
                }
            }
        }

        // Fallback: can't split effectively
        return [unit]
    }

    /// Balances pages to ensure better content distribution and no tiny fragments
    private func balancePages(_ initialPages: [String], width: CGFloat, height: CGFloat, font: UIFont) -> [String] {
        guard initialPages.count > 1 else {
            return initialPages
        }

        // Create measurement resources
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = font.pointSize * 0.15 // Reduced line spacing
        paragraphStyle.paragraphSpacing = font.pointSize * 0.3 // Control spacing between paragraphs
        paragraphStyle.headIndent = 0 // Minimize indentation for lists
        paragraphStyle.firstLineHeadIndent = 0 // Minimize first line indentation

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        // First, measure all pages to identify issues
        var pageMeasurements: [(page: String, height: CGFloat, fillRatio: CGFloat)] = []

        for page in initialPages {
            let pageHeight = measureTextHeight(page, width: width, attributes: baseAttributes)
            let fillRatio = pageHeight / height
            pageMeasurements.append((page: page, height: pageHeight, fillRatio: fillRatio))
        }

        // First pass: combine very small pages with adjacent pages
        var balancedPages: [String] = []
        var i = 0

        while i < pageMeasurements.count {
            let currentMeasurement = pageMeasurements[i]

            // If this is a very small page and not the first page, try to combine with previous
            if currentMeasurement.fillRatio < 0.4 && i > 0 && !currentMeasurement.page.isEmpty {
                let prevPage = balancedPages.last ?? ""
                let combinedPage = prevPage + (prevPage.isEmpty ? "" : "\n\n") + currentMeasurement.page
                let combinedHeight = measureTextHeight(combinedPage, width: width, attributes: baseAttributes)
                let effectiveMaxHeight = height * (maxPageFillThreshold - safetyMargin)

                if combinedHeight <= effectiveMaxHeight {
                    // It fits! Replace the previous page with the combined page
                    if !balancedPages.isEmpty {
                        balancedPages.removeLast()
                    }
                    balancedPages.append(combinedPage)
                    i += 1
                    continue
                }
            }

            // If this is a very small page and there's a next page, try to combine with next
            if currentMeasurement.fillRatio < 0.4 && i < pageMeasurements.count - 1 && !currentMeasurement.page.isEmpty {
                let nextPage = pageMeasurements[i + 1].page
                let combinedPage = currentMeasurement.page + "\n\n" + nextPage
                let combinedHeight = measureTextHeight(combinedPage, width: width, attributes: baseAttributes)
                let effectiveMaxHeight = height * (maxPageFillThreshold - safetyMargin)

                if combinedHeight <= effectiveMaxHeight {
                    // It fits! Add the combined page and skip the next page
                    balancedPages.append(combinedPage)
                    i += 2
                    continue
                }
            }

            // Normal sized page or couldn't combine, add it as is
            balancedPages.append(currentMeasurement.page)
            i += 1
        }

        // Second pass: check for underfilled pages and try to pull content from the next page
        var finalPages: [String] = []
        i = 0

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

                // Try to find a good break point by splitting the next page into semantic units
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
                            } else if newFillRatio > targetPageFillThreshold &&
                                     (bestFillRatio < minPageFillThreshold || bestFillRatio < newFillRatio) {
                                // If we're above target but the best so far is below minimum, update anyway
                                bestCombinedPage = newCombinedPage
                                bestCombinedHeight = newCombinedHeight
                                bestFillRatio = newFillRatio
                                bestRemainingPage = remainingUnits.joined(separator: "\n\n")
                            }

                            // If we've reached our target fill threshold, we can stop
                            if newFillRatio >= targetPageFillThreshold && newFillRatio <= maxPageFillThreshold - safetyMargin {
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

        // Third pass: check for overfilled pages and try to push content to the next page
        if finalPages.count > 1 {
            var rebalancedPages: [String] = []

            for i in 0..<finalPages.count {
                let page = finalPages[i]
                let pageHeight = measureTextHeight(page, width: width, attributes: baseAttributes)
                let pageFillRatio = pageHeight / height

                // If this page is too full and not the last page, try to push content to next page
                if pageFillRatio > maxPageFillThreshold - safetyMargin && i < finalPages.count - 1 {
                    // Split this page into units
                    let units = splitIntoSemanticUnits(page)

                    if units.count > 1 {
                        // Try to find a good split point
                        var currentPage = ""
                        var currentHeight: CGFloat = 0
                        var splitIndex = 0

                        for (j, unit) in units.enumerated() {
                            let newPage = currentPage.isEmpty ? unit : currentPage + "\n\n" + unit
                            let newHeight = measureTextHeight(newPage, width: width, attributes: baseAttributes)
                            let newRatio = newHeight / height

                            if newRatio <= targetPageFillThreshold || j == 0 {
                                // Still under target or first unit (must include at least one)
                                currentPage = newPage
                                currentHeight = newHeight
                                splitIndex = j + 1
                            } else {
                                // Over target, stop here
                                break
                            }
                        }

                        if splitIndex > 0 && splitIndex < units.count {
                            // We found a good split point
                            let remainingUnits = Array(units[splitIndex...])
                            let remainingPage = remainingUnits.joined(separator: "\n\n")

                            // Add the current page
                            rebalancedPages.append(currentPage)

                            // Combine remaining content with next page
                            if i + 1 < finalPages.count {
                                let nextPage = finalPages[i + 1]
                                finalPages[i + 1] = remainingPage + "\n\n" + nextPage
                            } else {
                                // Or add as a new page if this was the last page
                                rebalancedPages.append(remainingPage)
                            }
                        } else {
                            // Couldn't find a good split, keep as is
                            rebalancedPages.append(page)
                        }
                    } else {
                        // Can't split further, keep as is
                        rebalancedPages.append(page)
                    }
                } else {
                    // Page is fine or last page, keep as is
                    rebalancedPages.append(page)
                }
            }

            // Use the rebalanced pages if we made changes
            if rebalancedPages.count > 0 {
                finalPages = rebalancedPages
            }
        }

        // Final check: ensure no tiny fragments at the end
        if finalPages.count > 1 {
            let lastPage = finalPages.last ?? ""
            let lastPageHeight = measureTextHeight(lastPage, width: width, attributes: baseAttributes)
            let lastPageFillRatio = lastPageHeight / height

            // If the last page is small (less than 40% full), try to combine with previous page
            if lastPageFillRatio < 0.4 && lastPage.count < minContentThreshold * 2 {
                let prevPage = finalPages[finalPages.count - 2]
                let combinedPage = prevPage + (prevPage.isEmpty ? "" : "\n\n") + lastPage
                let combinedHeight = measureTextHeight(combinedPage, width: width, attributes: baseAttributes)

                // Use a higher threshold for the last page
                if combinedHeight <= height * maxPageFillThreshold {
                    finalPages.removeLast(2)
                    finalPages.append(combinedPage)
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
