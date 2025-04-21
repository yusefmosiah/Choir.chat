import Foundation
import SwiftUI
import Combine

/// Model for reward information received from the server
struct RewardInfo: Codable, Identifiable {
    var id: String { UUID().uuidString }
    let rewardType: String
    let rewardAmount: Int
    let success: Bool
    let digest: String?
    let error: String?
    
    // Additional fields based on reward type
    let similarity: Double?
    let citationCount: Int?
    let citedMessages: [String]?
    
    enum CodingKeys: String, CodingKey {
        case rewardType = "reward_type"
        case rewardAmount = "reward_amount"
        case success
        case digest
        case error
        case similarity
        case citationCount = "citation_count"
        case citedMessages = "cited_messages"
    }
    
    /// Returns the reward amount in CHOIR tokens (1 CHOIR = 1_000_000_000 units)
    var formattedAmount: String {
        let amount = Double(rewardAmount) / 1_000_000_000.0
        return String(format: "%.2f", amount)
    }
}

/// Service for handling rewards in the app
class RewardsService: ObservableObject {
    @Published var latestNoveltyReward: RewardInfo?
    @Published var latestCitationReward: RewardInfo?
    @Published var showRewardAlert: Bool = false
    @Published var rewardAlertMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    /// Process reward information received from the server
    func processReward(rewardInfo: RewardInfo) {
        DispatchQueue.main.async {
            if rewardInfo.rewardType == "novelty" {
                self.latestNoveltyReward = rewardInfo
                if rewardInfo.success {
                    self.showRewardAlert = true
                    self.rewardAlertMessage = "You earned \(rewardInfo.formattedAmount) CHOIR for your novel prompt!"
                }
            } else if rewardInfo.rewardType == "citation" {
                self.latestCitationReward = rewardInfo
                if rewardInfo.success {
                    self.showRewardAlert = true
                    self.rewardAlertMessage = "You earned \(rewardInfo.formattedAmount) CHOIR for \(rewardInfo.citationCount ?? 0) citations!"
                }
            }
        }
    }
    
    /// Process reward information from a phase response
    func processPhaseResponse(phase: String, response: [String: Any]) {
        if phase == "experience_vectors", let noveltyRewardDict = response["novelty_reward"] as? [String: Any] {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: noveltyRewardDict)
                let reward = try JSONDecoder().decode(RewardInfo.self, from: jsonData)
                processReward(rewardInfo: reward)
            } catch {
                print("Error decoding novelty reward: \(error)")
            }
        } else if phase == "yield", let citationRewardDict = response["citation_reward"] as? [String: Any] {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: citationRewardDict)
                let reward = try JSONDecoder().decode(RewardInfo.self, from: jsonData)
                processReward(rewardInfo: reward)
            } catch {
                print("Error decoding citation reward: \(error)")
            }
        }
    }
    
    /// Reset the reward alert
    func resetRewardAlert() {
        DispatchQueue.main.async {
            self.showRewardAlert = false
            self.rewardAlertMessage = ""
        }
    }
}

/// View modifier to show reward alerts
struct RewardAlertModifier: ViewModifier {
    @ObservedObject var rewardsService: RewardsService
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $rewardsService.showRewardAlert) {
                Alert(
                    title: Text("Reward Earned!"),
                    message: Text(rewardsService.rewardAlertMessage),
                    dismissButton: .default(Text("OK")) {
                        rewardsService.resetRewardAlert()
                    }
                )
            }
    }
}

extension View {
    func withRewardAlerts(rewardsService: RewardsService) -> some View {
        self.modifier(RewardAlertModifier(rewardsService: rewardsService))
    }
}
