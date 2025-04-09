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
}
