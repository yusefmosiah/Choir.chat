//
//  Item.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//

import Foundation
import SwiftUI

class ChoirThread: ObservableObject, Identifiable, Hashable {
   let id: UUID
   let title: String
   @Published var messages: [Message] = []

   init(id: UUID = UUID(), title: String? = nil) {
       self.id = id
       self.title = title ?? "ChoirThread \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
       print("Created new thread: \(self.title)")
   }

   // Hashable conformance
   static func == (lhs: ChoirThread, rhs: ChoirThread) -> Bool {
       lhs.id == rhs.id
   }

   func hash(into hasher: inout Hasher) {
       hasher.combine(id)
   }
}

struct Message: Identifiable, Equatable {
   let id: UUID
   var content: String
   let isUser: Bool
   let timestamp: Date
   var chorusResult: MessageChorusResult?

   init(id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        chorusResult: MessageChorusResult? = nil) {
       self.id = id
       self.content = content
       self.isUser = isUser
       self.timestamp = timestamp
       self.chorusResult = chorusResult
   }

   // Equatable conformance
   static func == (lhs: Message, rhs: Message) -> Bool {
       lhs.id == rhs.id
   }
}

struct MessageChorusResult: Equatable {
   let phases: [Phase: String]

   static func == (lhs: MessageChorusResult, rhs: MessageChorusResult) -> Bool {
       lhs.phases == rhs.phases
   }
}
