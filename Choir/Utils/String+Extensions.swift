import Foundation

extension String {
    /// Returns a string containing the first `count` words of the original string.
    /// Words are separated by whitespace and newline characters.
    /// Punctuation attached to words is included.
    ///
    /// - Parameter count: The maximum number of words to return.
    /// - Returns: A new string with the first `count` words, or the original string if it has `count` or fewer words.
    func prefixWords(_ count: Int) -> String {
        guard count > 0 else { return "" }

        // Split into components separated by whitespace and newlines
        let components = self.components(separatedBy: .whitespacesAndNewlines)

        // Filter out empty strings that can result from multiple spaces
        let words = components.filter { !$0.isEmpty }

        // Take the specified number of words, or fewer if not enough exist
        let prefix = words.prefix(count)

        // Join the words back together with a single space
        return prefix.joined(separator: " ")
    }
    
    /// Converts vector ID references in the form #123 into clickable deep links.
    /// Uses a bold formatting approach to make them visually distinct.
    ///
    /// - Returns: A string with vector references converted to links.
    func convertVectorReferencesToDeepLinks() -> String {
        // This pattern matches standalone #nnn references in text
        // Looking for a hash followed by 1+ digits, with word boundaries
        let pattern = "(?<=\\s|\\(|\\[|^)(#\\d+)(?=\\s|\\)|\\]|,|\\.|$)"
        let vectorIdRegex = try? NSRegularExpression(pattern: pattern, options: [])
        
        guard let regex = vectorIdRegex else { 
            print("🔗 LINKS: Failed to create regex for vector references")
            return self 
        }
        
        let nsString = NSString(string: self)
        let range = NSRange(location: 0, length: nsString.length)
        
        // Find all matches for vector references
        let matches = regex.matches(in: self, options: [], range: range)
        
        print("🔗 LINKS: Found \(matches.count) vector references in text")
        
        // If no matches, return original text
        if matches.isEmpty {
            return self
        }
        
        // Track all vector IDs we find for logging
        var foundVectorIds: [Int] = []
        
        // Process in reverse order to not affect the indices of earlier matches
        var result = self
        for match in matches.reversed() {
            let matchRange = match.range
            let matchText = nsString.substring(with: matchRange)
            
            // Extract the numeric part by removing the '#' prefix
            let vectorId = matchText.dropFirst()
            
            // Track the vector IDs we find
            if let numericId = Int(vectorId) {
                foundVectorIds.append(numericId)
            }
            
            // Use bold formatting to make them visually distinct
            let replacement = "[**\(matchText)**](choir://vector/\(vectorId))"
            
            // Apply the replacement
            if let range = Range(matchRange, in: result) {
                result.replaceSubrange(range, with: replacement)
            }
        }
        
        // Log all vector IDs we found
        if !foundVectorIds.isEmpty {
            print("🔗 LINKS: Found vector IDs: \(foundVectorIds.sorted())")
        }
        
        return result
    }
    
    /// Extracts all vector reference numbers from text.
    /// Used for debugging and ensuring vector results are available.
    ///
    /// - Returns: Array of vector reference numbers (without the # prefix)
    func extractVectorReferenceNumbers() -> [Int] {
        let pattern = "(?<=\\s|\\(|\\[|^)(#\\d+)(?=\\s|\\)|\\]|,|\\.|$)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { 
            return [] 
        }
        
        let nsString = NSString(string: self)
        let range = NSRange(location: 0, length: nsString.length)
        let matches = regex.matches(in: self, options: [], range: range)
        
        var vectorIds: [Int] = []
        for match in matches {
            let matchRange = match.range
            let matchText = nsString.substring(with: matchRange)
            let vectorIdString = matchText.dropFirst() // Remove # prefix
            if let vectorId = Int(vectorIdString) {
                vectorIds.append(vectorId)
            }
        }
        
        return vectorIds.sorted()
    }
}
