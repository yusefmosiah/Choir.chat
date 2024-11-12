import Foundation

enum Phase: String, CaseIterable, Identifiable {
    case action
    case experience
    case intention
    case observation
    case understanding
    case yield

    var id: String { rawValue }

    var description: String {
        switch self {
        case .action: return "Initial Response"
        case .experience: return "Finding Context"
        case .intention: return "Analyzing Intent"
        case .observation: return "Observing Patterns"
        case .understanding: return "Checking Understanding"
        case .yield: return "Final Response"
        }
    }

    var symbol: String {
        switch self {
        case .action: return "bolt.fill"
        case .experience: return "brain.head.profile"
        case .intention: return "target"
        case .observation: return "eye.fill"
        case .understanding: return "checkmark.circle.fill"
        case .yield: return "arrow.down.circle.fill"
        }
    }
}
