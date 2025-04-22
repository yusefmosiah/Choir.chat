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

    /// Converts vector ID references into clickable deep links.
    /// Handles both new format (#V{vector_id}-{position}) and legacy format (#123).
    /// Uses a bold formatting approach to make them visually distinct.
    ///
    /// - Returns: A string with vector references converted to links.
    func convertVectorReferencesToDeepLinks() -> String {
        // Pattern for new format: #V{vector_id} (with or without position number)
        // This pattern matches formats like #V8defd5b8-b25f-e887-8f50-9459ce5c1628 or #V8defd5b8-b25f-e887-8f50-9459ce5c1628-1
        let newFormatPattern = "(?<=\\s|\\(|\\[|^)(#V[\\w-]+(?:-\\d+)?)(?=\\s|\\)|\\]|,|\\.|$)"

        // Pattern for legacy format: #{position_number}
        let legacyPattern = "(?<=\\s|\\(|\\[|^)(#\\d+)(?=\\s|\\)|\\]|,|\\.|$)"

        // Create regex for both patterns
        let newFormatRegex = try? NSRegularExpression(pattern: newFormatPattern, options: [])
        let legacyRegex = try? NSRegularExpression(pattern: legacyPattern, options: [])

        guard let newRegex = newFormatRegex, let oldRegex = legacyRegex else {
            return self
        }

        let nsString = NSString(string: self)
        let range = NSRange(location: 0, length: nsString.length)

        // Find all matches for both formats
        let newFormatMatches = newRegex.matches(in: self, options: [], range: range)
        let legacyMatches = oldRegex.matches(in: self, options: [], range: range)

        // If no matches of either type, return original text
        if newFormatMatches.isEmpty && legacyMatches.isEmpty {
            return self
        }

        // Process in reverse order to not affect the indices of earlier matches
        var result = self

        // Process new format matches first
        for match in newFormatMatches.reversed() {
            let matchRange = match.range
            let matchText = nsString.substring(with: matchRange)

            // Extract the vector_id part from formats like:
            // #V8defd5b8-b25f-e887-8f50-9459ce5c1628 or #V8defd5b8-b25f-e887-8f50-9459ce5c1628-1
            // The full match is used as the display text
            // The vector_id is extracted for the API call
            if let regex = try? NSRegularExpression(pattern: "#V([\\w-]+)(?:-(\\d+))?", options: []),
               let idMatch = regex.firstMatch(in: matchText, options: [], range: NSRange(location: 0, length: matchText.count)) {

                let nsMatchText = NSString(string: matchText)
                let vectorId = nsMatchText.substring(with: idMatch.range(at: 1))

                // Use bold formatting to make them visually distinct
                // The URL format is choir://vector/{vector_id} to call the API endpoint
                let replacement = "[**\(matchText)**](choir://vector/\(vectorId))"

                // Apply the replacement
                if let range = Range(matchRange, in: result) {
                    result.replaceSubrange(range, with: replacement)
                }
            }
        }

        // Process legacy format matches
        for match in legacyMatches.reversed() {
            let matchRange = match.range
            let matchText = nsString.substring(with: matchRange)

            // Skip if this is actually part of a new format reference
            // This prevents double-processing references like #V123-456
            let fullText = nsString as String
            let startIdx = matchRange.location
            if startIdx >= 2 {
                let prevChars = fullText[fullText.index(fullText.startIndex, offsetBy: startIdx-2)..<fullText.index(fullText.startIndex, offsetBy: startIdx)]
                if prevChars == "#V" {
                    continue
                }
            }

            // Extract the numeric part by removing the '#' prefix
            let vectorId = matchText.dropFirst()

            // Use bold formatting to make them visually distinct
            let replacement = "[**\(matchText)**](choir://vector/\(vectorId))"

            // Apply the replacement
            if let range = Range(matchRange, in: result) {
                result.replaceSubrange(range, with: replacement)
            }
        }

        return result
    }

    /// Extracts all vector reference IDs from text.
    /// Handles both new format (#V{vector_id}-{position}) and legacy format (#123).
    /// Used for debugging and ensuring vector results are available.
    ///
    /// - Returns: Array of vector reference IDs (actual vector IDs for new format, position numbers for legacy format)
    func extractVectorReferenceIDs() -> [String] {
        // Pattern for new format: #V{vector_id} (with or without position number)
        // This pattern matches formats like #V8defd5b8-b25f-e887-8f50-9459ce5c1628 or #V8defd5b8-b25f-e887-8f50-9459ce5c1628-1
        let newFormatPattern = "(?<=\\s|\\(|\\[|^)(#V[\\w-]+(?:-\\d+)?)(?=\\s|\\)|\\]|,|\\.|$)"

        // Pattern for legacy format: #{position_number}
        let legacyPattern = "(?<=\\s|\\(|\\[|^)(#\\d+)(?=\\s|\\)|\\]|,|\\.|$)"

        // Create regex for both patterns
        let newFormatRegex = try? NSRegularExpression(pattern: newFormatPattern, options: [])
        let legacyRegex = try? NSRegularExpression(pattern: legacyPattern, options: [])

        guard let newRegex = newFormatRegex, let oldRegex = legacyRegex else {
            return []
        }

        let nsString = NSString(string: self)
        let range = NSRange(location: 0, length: nsString.length)

        // Find all matches for both formats
        let newFormatMatches = newRegex.matches(in: self, options: [], range: range)
        let legacyMatches = oldRegex.matches(in: self, options: [], range: range)

        var vectorIds: [String] = []

        // Process new format matches
        for match in newFormatMatches {
            let matchRange = match.range
            let matchText = nsString.substring(with: matchRange)

            // Extract the vector ID from formats like:
            // #V8defd5b8-b25f-e887-8f50-9459ce5c1628 or #V8defd5b8-b25f-e887-8f50-9459ce5c1628-1
            if let regex = try? NSRegularExpression(pattern: "#V([\\w-]+)(?:-(\\d+))?", options: []),
               let idMatch = regex.firstMatch(in: matchText, options: [], range: NSRange(location: 0, length: matchText.count)) {

                let nsMatchText = NSString(string: matchText)
                let vectorId = nsMatchText.substring(with: idMatch.range(at: 1))
                vectorIds.append(vectorId)
            }
        }

        // Process legacy format matches
        for match in legacyMatches {
            let matchRange = match.range
            let matchText = nsString.substring(with: matchRange)

            // Skip if this is actually part of a new format reference
            let fullText = nsString as String
            let startIdx = matchRange.location
            if startIdx >= 2 {
                let prevChars = fullText[fullText.index(fullText.startIndex, offsetBy: startIdx-2)..<fullText.index(fullText.startIndex, offsetBy: startIdx)]
                if prevChars == "#V" {
                    continue
                }
            }

            // Extract the numeric part by removing the '#' prefix
            let vectorIdString = matchText.dropFirst() // Remove # prefix
            vectorIds.append(String(vectorIdString))
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
