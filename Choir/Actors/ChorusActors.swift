import Foundation

protocol ChorusPhase: Actor {
    func process(_ input: String) async -> String
}

actor ActionPhase: ChorusPhase {
    func process(_ input: String) async -> String {
        try? await Task.sleep(for: .seconds(1))  // 1 second
        return "Direct response: \(input)"
    }
}

actor ExperiencePhase: ChorusPhase {
    func process(_ input: String) async -> String {
        try? await Task.sleep(for: .seconds(2))  // 3 seconds
        return "Related experience: Found 3 relevant priors for '\(input)'"
    }
}

actor IntentionPhase: ChorusPhase {
    func process(_ input: String) async -> String {
        try? await Task.sleep(for: .seconds(2))  // 5 seconds
        return "Goal analysis: User wants to understand '\(input)'"
    }
}

actor ObservationPhase: ChorusPhase {
    func process(_ input: String) async -> String {
        try? await Task.sleep(for: .seconds(2))  // 7 seconds
        return "Observed patterns in: '\(input)'"
    }
}

actor UnderstandingPhase: ChorusPhase {
    func process(_ input: String) async -> String {
        try? await Task.sleep(for: .seconds(2))  // 9 seconds
        return "Deeper understanding of: '\(input)'"
    }
}

actor YieldPhase: ChorusPhase {
    func process(_ input: String) async -> String {
        try? await Task.sleep(for: .seconds(2))  // 11 seconds
        return "Final synthesis of: '\(input)'"
    }
}

@MainActor
class ChorusCoordinator: ObservableObject {
    private let action = ActionPhase()
    private let experience = ExperiencePhase()
    private let intention = IntentionPhase()
    private let observation = ObservationPhase()
    private let understanding = UnderstandingPhase()
    private let yield = YieldPhase()

    @Published var responses: [ChorusResponse.Phase: String] = [:]

    func process(_ input: String) async {
        // Start with immediate action response
        responses[.action] = await action.process(input)

        // Process remaining phases sequentially to maintain order
        responses[.experience] = await experience.process(input)
        responses[.intention] = await intention.process(input)
        responses[.observation] = await observation.process(input)
        responses[.understanding] = await understanding.process(input)
        responses[.yield] = await yield.process(input)
    }
}
