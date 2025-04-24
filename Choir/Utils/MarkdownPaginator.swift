import Foundation
import SwiftUI

/// A class that handles pagination of markdown content while preserving formatting across page boundaries
class MarkdownPaginator {
    
    /// Represents a markdown block type
    enum BlockType {
        case bulletedList
        case numberedList
        case codeBlock
        case blockquote
        case paragraph
        case heading
    }
    
    /// Represents the context at a specific point in the markdown
    struct MarkdownContext {
        let blockType: BlockType
        let indentationLevel: Int
        let listItemNumber: Int? // For numbered lists
        let codeBlockLanguage: String? // For code blocks
        
        /// Returns the prefix needed to continue this context on a new page
        func continuationPrefix() -> String {
            var prefix = ""
            
            // Add indentation
            if indentationLevel > 0 {
                prefix += String(repeating: "  ", count: indentationLevel)
            }
            
            // Add block-specific prefix
            switch blockType {
            case .bulletedList:
                prefix += "- "
            case .numberedList:
                if let number = listItemNumber {
                    prefix += "\(number). "
                } else {
                    prefix += "1. "
                }
            case .codeBlock:
                if let language = codeBlockLanguage {
                    prefix += "```\(language)\n"
                } else {
                    prefix += "```\n"
                }
            case .blockquote:
                prefix += "> "
            case .paragraph, .heading:
                // No special prefix needed
                break
            }
            
            return prefix
        }
    }
    
    /// The text measurer used to determine how much text fits on a page
    private let textMeasurer: TextMeasurer
    
    init(textMeasurer: TextMeasurer) {
        self.textMeasurer = textMeasurer
    }
    
    /// Paginates markdown content while preserving formatting across page boundaries
    /// - Parameters:
    ///   - text: The markdown text to paginate
    ///   - width: The available width for each page
    ///   - height: The available height for each page
    /// - Returns: An array of strings, each representing a page of content
    func paginateMarkdown(_ text: String, width: CGFloat, height: CGFloat) -> [String] {
        var pages: [String] = []
        var remainingText = text
        
        while !remainingText.isEmpty {
            // Get the text that fits on this page
            let pageText = textMeasurer.fitTextToHeight(
                text: remainingText,
                width: width,
                height: height
            )
            
            guard !pageText.isEmpty else {
                // If we couldn't fit any text, take at least one line to avoid infinite loops
                let firstLine = remainingText.components(separatedBy: .newlines).first ?? remainingText
                pages.append(firstLine)
                
                if remainingText.count > firstLine.count {
                    let index = remainingText.index(remainingText.startIndex, offsetBy: firstLine.count + 1)
                    remainingText = String(remainingText[index...])
                } else {
                    remainingText = ""
                }
                continue
            }
            
            // Add this page to our result
            pages.append(pageText)
            
            if pageText.count < remainingText.count {
                // Get the context at the split point
                let context = analyzeContextAtSplitPoint(
                    fullText: remainingText,
                    splitPoint: pageText.count
                )
                
                // Remove the text we've already paginated
                let index = remainingText.index(remainingText.startIndex, offsetBy: pageText.count)
                remainingText = String(remainingText[index...])
                
                // Add the continuation prefix to the remaining text if needed
                if let context = context {
                    remainingText = context.continuationPrefix() + remainingText
                }
            } else {
                remainingText = ""
            }
        }
        
        return pages
    }
    
    /// Analyzes the context at a split point in the markdown
    /// - Parameters:
    ///   - fullText: The full text being paginated
    ///   - splitPoint: The character index where the split occurs
    /// - Returns: The markdown context at the split point, or nil if no special context is needed
    private func analyzeContextAtSplitPoint(fullText: String, splitPoint: Int) -> MarkdownContext? {
        // Get the text up to the split point
        let textBeforeSplit = String(fullText.prefix(splitPoint))
        
        // Split into lines
        let lines = textBeforeSplit.components(separatedBy: .newlines)
        
        // Start from the last line and work backwards to find the context
        var currentLineIndex = lines.count - 1
        var inCodeBlock = false
        var codeBlockLanguage: String? = nil
        
        // Check if we're in the middle of a code block
        for (index, line) in lines.enumerated().reversed() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.hasPrefix("```") {
                inCodeBlock = !inCodeBlock
                
                // If this is the start of a code block, extract the language
                if inCodeBlock {
                    let languagePart = trimmedLine.dropFirst(3)
                    if !languagePart.isEmpty {
                        codeBlockLanguage = String(languagePart)
                    }
                    break
                }
            }
        }
        
        // If we're in a code block, return that context
        if inCodeBlock {
            return MarkdownContext(
                blockType: .codeBlock,
                indentationLevel: 0,
                listItemNumber: nil,
                codeBlockLanguage: codeBlockLanguage
            )
        }
        
        // Find the last non-empty line
        while currentLineIndex >= 0 && lines[currentLineIndex].trimmingCharacters(in: .whitespaces).isEmpty {
            currentLineIndex -= 1
        }
        
        // If we couldn't find a non-empty line, no special context is needed
        guard currentLineIndex >= 0 else {
            return nil
        }
        
        let lastLine = lines[currentLineIndex]
        let trimmedLastLine = lastLine.trimmingCharacters(in: .whitespaces)
        let indentationLevel = getIndentationLevel(lastLine)
        
        // Check for different block types
        if trimmedLastLine.hasPrefix("- ") || trimmedLastLine.hasPrefix("* ") {
            // Bulleted list
            return MarkdownContext(
                blockType: .bulletedList,
                indentationLevel: indentationLevel,
                listItemNumber: nil,
                codeBlockLanguage: nil
            )
        } else if let listItemNumber = extractNumberedListItem(trimmedLastLine) {
            // Numbered list
            // Find the next number in the sequence by looking at previous list items
            var nextNumber = listItemNumber + 1
            
            // Look for the next list item in the remaining text
            let remainingText = String(fullText.suffix(from: fullText.index(fullText.startIndex, offsetBy: splitPoint)))
            let remainingLines = remainingText.components(separatedBy: .newlines)
            
            // Check if the next line is a list item with the same indentation
            if !remainingLines.isEmpty {
                let nextLine = remainingLines[0]
                let nextLineIndentation = getIndentationLevel(nextLine)
                
                // If the indentation is the same, this is a continuation of the same list
                if nextLineIndentation == indentationLevel {
                    // Use the same list item number to continue the current item
                    nextNumber = listItemNumber
                }
            }
            
            return MarkdownContext(
                blockType: .numberedList,
                indentationLevel: indentationLevel,
                listItemNumber: nextNumber,
                codeBlockLanguage: nil
            )
        } else if trimmedLastLine.hasPrefix(">") {
            // Blockquote
            return MarkdownContext(
                blockType: .blockquote,
                indentationLevel: indentationLevel,
                listItemNumber: nil,
                codeBlockLanguage: nil
            )
        }
        
        // For paragraphs, we only need to preserve indentation
        if indentationLevel > 0 {
            return MarkdownContext(
                blockType: .paragraph,
                indentationLevel: indentationLevel,
                listItemNumber: nil,
                codeBlockLanguage: nil
            )
        }
        
        // No special context needed
        return nil
    }
    
    /// Gets the indentation level of a line (number of leading spaces / 2)
    private func getIndentationLevel(_ line: String) -> Int {
        var count = 0
        for char in line {
            if char == " " {
                count += 1
            } else {
                break
            }
        }
        return count / 2
    }
    
    /// Extracts the list item number from a numbered list item
    private func extractNumberedListItem(_ line: String) -> Int? {
        // Match patterns like "1. " or "123. "
        let pattern = "^\\s*(\\d+)\\."
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let nsString = NSString(string: line)
        let range = NSRange(location: 0, length: nsString.length)
        
        if let match = regex.firstMatch(in: line, options: [], range: range) {
            let numberString = nsString.substring(with: match.range(at: 1))
            return Int(numberString)
        }
        
        return nil
    }
}
