//
//  Item.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//

import Foundation
import SwiftUI

class Thread: Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    var messages: [Message]

    init(id: UUID = UUID(), createdAt: Date = Date(), messages: [Message] = []) {
        self.id = id
        self.createdAt = createdAt
        self.messages = messages
    }

    // Hashable conformance
    static func == (lhs: Thread, rhs: Thread) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Message: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var chorusResponses: [Phase: [String]]?

    init(content: String, isUser: Bool, timestamp: Date = Date(), chorusResponses: [Phase: [String]]? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.chorusResponses = chorusResponses
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
