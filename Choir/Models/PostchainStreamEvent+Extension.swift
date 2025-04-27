//
//  PostchainStreamEvent+Extension.swift
//  Choir
//
//  Created by Augment on 6/10/24.
//

import Foundation

extension PostchainStreamEvent {
    /// Create a PostchainStreamEvent from a PostchainEvent, handling the case where citation information might not be available
    init(from event: PostchainEvent) {
        self.phase = event.phase
        self.status = event.status
        self.content = event.content
        self.provider = event.provider
        self.modelName = event.modelName
        self.webResults = event.webResults
        self.vectorResults = event.vectorResults
        self.noveltyReward = event.noveltyReward
        self.maxSimilarity = event.maxSimilarity
        self.citationReward = event.citationReward
        self.citationExplanations = event.citationExplanations
    }
}
