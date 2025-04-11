import SwiftUI
import Foundation

/// Service responsible for pagination-related calculations and operations
class PaginationService {
    
    /// Calculate the total number of pages needed for the given content and size
    /// - Parameters:
    ///   - markdownText: The markdown text to paginate
    ///   - searchResults: Array of search results to include in pagination
    ///   - size: Available size for rendering
    /// - Returns: Total number of pages
    func calculateTotalPages(markdownText: String, searchResults: [UnifiedSearchResult], size: CGSize) -> Int {
        guard size.height > 0, size.width > 0 else {
            print("Warning: calculateTotalPages called with zero size.")
            return 1
        }
        
        // Create a text measurer to calculate text fitting
        let measurer = TextMeasurer(sizeCategory: .medium)
        
        // Calculate text pages
        let textPages = splitMarkdownIntoPages(markdownText, size: size, measurer: measurer)
        let textPagesCount = textPages.count
        
        // Calculate result pages
        let resultPagesCount = calculateResultPagesCount(searchResults)
        
        // Return total pages (at least 1)
        let total = textPagesCount + resultPagesCount
        return max(1, total)
    }
    
    /// Split markdown text into pages based on available size
    /// - Parameters:
    ///   - text: The markdown text to split
    ///   - size: Available size for rendering
    ///   - measurer: TextMeasurer instance to use for calculations
    /// - Returns: Array of page content strings
    func splitMarkdownIntoPages(_ text: String, size: CGSize, measurer: TextMeasurer) -> [String] {
        let textHeight = size.height - 40 // Account for padding
        var pages: [String] = []
        var remainingText = text
        
        // Handle empty text case
        if text.isEmpty {
            return []
        }
        
        // Split text into pages
        while !remainingText.isEmpty {
            let pageText = measurer.fitTextToHeight(
                text: remainingText,
                width: size.width - 8, // Account for padding
                height: textHeight
            )
            
            // Handle potential infinite loop
            if pageText.isEmpty && !remainingText.isEmpty {
                print("Warning: TextMeasurer returned empty page for non-empty text. Breaking loop.")
                pages.append(remainingText)
                break
            }
            
            pages.append(pageText)
            
            // Update remaining text
            if pageText.count < remainingText.count {
                let index = remainingText.index(remainingText.startIndex, offsetBy: pageText.count)
                remainingText = String(remainingText[index...])
            } else {
                remainingText = ""
            }
        }
        
        return pages
    }
    
    /// Calculate the number of pages needed for search results
    /// - Parameter searchResults: Array of search results
    /// - Returns: Number of pages needed for results
    private func calculateResultPagesCount(_ searchResults: [UnifiedSearchResult]) -> Int {
        let itemsPerPage = 5 // Results per page
        return searchResults.isEmpty ? 0 : Int(ceil(Double(searchResults.count) / Double(itemsPerPage)))
    }
    
    /// Chunk search results into pages
    /// - Parameters:
    ///   - results: Array of search results
    ///   - itemsPerPage: Number of items per page
    /// - Returns: Array of result page arrays
    func chunkResults(_ results: [UnifiedSearchResult], itemsPerPage: Int = 5) -> [[UnifiedSearchResult]] {
        stride(from: 0, to: results.count, by: itemsPerPage).map {
            Array(results[$0..<min($0 + itemsPerPage, results.count)])
        }
    }
}