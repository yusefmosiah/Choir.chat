import Foundation

enum Phase: CaseIterable {
    case action
    case experience
    case intention
    case observation
    case understanding
    case yield

    var symbol: String {
        switch self {
        case .action: "bolt.fill"         // Immediate response
        case .experience: "book.fill"      // Prior knowledge
        case .intention: "target"          // Goal analysis
        case .observation: "eye.fill"      // Pattern recognition
        case .understanding: "brain"       // Deep thinking
        case .yield: "checkmark.circle"    // Final synthesis
        }
    }
}
