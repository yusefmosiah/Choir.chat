//
//  ChoirApp.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//
import SwiftUI

@main
struct ChoirApp: App {
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            TextSelectionSheetProvider {
                appCoordinator.rootView()
            }
            .environmentObject(appCoordinator.walletManager)
            .environmentObject(appCoordinator.authService)
            .onAppear {
                let threads = ThreadPersistenceService.shared.loadAllThreads()
                let threadIDs = Set(threads.map { $0.id })
                // TODO: Store threadIDs in a shared model or environment object

                print("App appeared - checking authentication state")
            }
            .onChange(of: appCoordinator.currentAuthState) { newState in
                print("Auth state changed to \(newState)")
            }
        }
    }
}
