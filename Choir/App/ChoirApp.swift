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

    var body: some Scene {
        WindowGroup {
            TextSelectionSheetProvider {
                ContentView()
                    .environmentObject(walletManager)
            }
        }
    }
}
