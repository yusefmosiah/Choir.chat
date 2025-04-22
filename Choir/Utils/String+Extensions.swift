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

    /// Converts vector ID references in <vid> tags into clickable deep links.
    /// Uses a bold formatting approach to make them visually distinct.
    ///
    /// - Returns: A string with vector references converted to links.
    func convertVectorReferencesToDeepLinks() -> String {
        // Pattern for <vid> tags: <vid>vector_id</vid>
        // Allow for all possible vector ID formats (UUIDs, hashes, etc.)
        let vidTagPattern = "<vid>([^<>]+)</vid>"

        // Create regex for the pattern
        guard let vidTagRegex = try? NSRegularExpression(pattern: vidTagPattern, options: []) else {
            return self
        }

        let nsString = NSString(string: self)
        let range = NSRange(location: 0, length: nsString.length)

        // Find all matches for the vid tag format
        let vidTagMatches = vidTagRegex.matches(in: self, options: [], range: range)

        // If no matches, return original text
        if vidTagMatches.isEmpty {
            return self
        }

        // Process in reverse order to not affect the indices of earlier matches
        var result = self

        // Process vid tag matches
        for match in vidTagMatches.reversed() {
            let matchRange = match.range
            let vectorId = nsString.substring(with: match.range(at: 1))

            // Create a shortened display version of the vector ID (first 8 chars)
            let shortDisplayId = vectorId.prefix(8)

            // Use bold formatting to make them visually distinct
            // The URL format is choir://vector/{vector_id} to call the API endpoint
            let replacement = "[**V\(shortDisplayId)**](choir://vector/\(vectorId))"

            // Apply the replacement
            if let range = Range(matchRange, in: result) {
                result.replaceSubrange(range, with: replacement)
            }
        }

        // Also handle legacy format: #{position_number} for backward compatibility
        let legacyPattern = "(?<=\\s|\\(|\\[|^)(#\\d+)(?=\\s|\\)|\\]|,|\\.|$)"
        if let legacyRegex = try? NSRegularExpression(pattern: legacyPattern, options: []) {
            let legacyMatches = legacyRegex.matches(in: result, options: [], range: NSRange(location: 0, length: result.count))

            for match in legacyMatches.reversed() {
                let matchRange = match.range
                let matchText = NSString(string: result).substring(with: matchRange)

                // Extract the numeric part by removing the '#' prefix
                let vectorId = matchText.dropFirst()

                // Use bold formatting to make them visually distinct
                let replacement = "[**\(matchText)**](choir://vector/\(vectorId))"

                // Apply the replacement
                if let range = Range(matchRange, in: result) {
                    result.replaceSubrange(range, with: replacement)
                }
            }
        }

        return result
    }

    /// Extracts all vector reference IDs from text.
    /// Handles both new format (<vid>vector_id</vid>) and legacy format (#123).
    /// Used for debugging and ensuring vector results are available.
    ///
    /// - Returns: Array of vector reference IDs (actual vector IDs for new format, position numbers for legacy format)
    func extractVectorReferenceIDs() -> [String] {
        // Pattern for <vid> tags: <vid>vector_id</vid>
        // Allow for all possible vector ID formats (UUIDs, hashes, etc.)
        let vidTagPattern = "<vid>([^<>]+)</vid>"

        // Pattern for legacy format: #{position_number}
        let legacyPattern = "(?<=\\s|\\(|\\[|^)(#\\d+)(?=\\s|\\)|\\]|,|\\.|$)"

        // Create regex for both patterns
        let vidTagRegex = try? NSRegularExpression(pattern: vidTagPattern, options: [])
        let legacyRegex = try? NSRegularExpression(pattern: legacyPattern, options: [])

        var vectorIds: [String] = []

        let nsString = NSString(string: self)
        let range = NSRange(location: 0, length: nsString.length)

        // Process <vid> tag matches
        if let vidRegex = vidTagRegex {
            let vidTagMatches = vidRegex.matches(in: self, options: [], range: range)
            for match in vidTagMatches {
                let vectorId = nsString.substring(with: match.range(at: 1))
                vectorIds.append(vectorId)
            }
        }

        // Process legacy format matches
        if let legacyRegex = legacyRegex {
            let legacyMatches = legacyRegex.matches(in: self, options: [], range: range)
            for match in legacyMatches {
                let matchRange = match.range
                let matchText = nsString.substring(with: matchRange)

                // Extract the numeric part by removing the '#' prefix
                let vectorIdString = matchText.dropFirst() // Remove # prefix
                vectorIds.append(String(vectorIdString))
            }
        }

        return vectorIds
    }

    /// Legacy method for backward compatibility
    /// - Returns: Array of vector reference numbers (without the # prefix)
    func extractVectorReferenceNumbers() -> [Int] {
        let vectorIds = extractVectorReferenceIDs()
        return vectorIds.compactMap { Int($0) }
    }
}
