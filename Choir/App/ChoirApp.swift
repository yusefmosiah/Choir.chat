//
//  ChoirApp.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//
import SwiftUI

@main
struct ChoirApp: App {
    var body: some Scene {
        WindowGroup {
            TextSelectionSheetProvider {
                ContentView()
            }
            .onAppear {
                let threads = ThreadPersistenceService.shared.loadAllThreads()
                let threadIDs = Set(threads.map { $0.id })
                // TODO: Store threadIDs in a shared model or environment object
            }
        }
    }
}
