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

    /// Optimizes text for pagination by temporarily replacing long vector IDs with shorter placeholders
    /// This helps pagination calculations by reducing the effective length of the text
    ///
    /// - Returns: A tuple containing the optimized text and a mapping to restore the original IDs
    func optimizeForPagination() -> (optimizedText: String, idMapping: [String: String]) {
        // Pattern for markdown links with vector IDs: [**V12345678**](choir://vector/12345678-1234-1234-1234-1234567890ab)
        let vectorLinkPattern = "\\[\\*\\*V([^\\]]+)\\*\\*\\]\\(choir://vector/([^\\)]+)\\)"

        // Create regex for the pattern
        guard let vectorLinkRegex = try? NSRegularExpression(pattern: vectorLinkPattern, options: []) else {
            return (self, [:])
        }

        let nsString = NSString(string: self)
        let range = NSRange(location: 0, length: nsString.length)

        // Find all matches for vector links
        let vectorLinkMatches = vectorLinkRegex.matches(in: self, options: [], range: range)

        // If no matches, return original text
        if vectorLinkMatches.isEmpty {
            return (self, [:])
        }

        // Process in reverse order to not affect the indices of earlier matches
        var result = self
        var idMapping: [String: String] = [:]

        // Generate unique placeholder IDs
        for (index, match) in vectorLinkMatches.enumerated().reversed() {
            let matchRange = match.range
            let displayId = nsString.substring(with: match.range(at: 1))
            let fullVectorId = nsString.substring(with: match.range(at: 2))

            // Create a unique placeholder ID
            let placeholderId = "placeholder_\(index)"

            // Store the mapping for later restoration
            idMapping[placeholderId] = fullVectorId

            // Create a replacement with the same display ID but a shorter URL
            let replacement = "[**V\(displayId)**](choir://vector/\(placeholderId))"

            // Apply the replacement
            if let range = Range(matchRange, in: result) {
                result.replaceSubrange(range, with: replacement)
            }
        }

        return (result, idMapping)
    }

    /// Restores the original vector IDs from the optimized text using the provided mapping
    ///
    /// - Parameter idMapping: The mapping from placeholder IDs to original vector IDs
    /// - Returns: The text with original vector IDs restored
    func restoreVectorIds(idMapping: [String: String]) -> String {
        if idMapping.isEmpty {
            return self
        }

        var result = self

        // Replace each placeholder with its original ID
        for (placeholderId, originalId) in idMapping {
            // Pattern for the placeholder in a link
            let pattern = "choir://vector/\(placeholderId)"

            // Replace all occurrences
            result = result.replacingOccurrences(of: pattern, with: "choir://vector/\(originalId)")
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
