//
//  ChoirApp.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//

import SwiftUI

@main
struct ChoirApp: App {
    @StateObject var walletManager = WalletManager()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TextSelectionSheetProvider {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext) // Inject Core Data context
                    .environmentObject(walletManager)
            }
        }
    }
}
