//
//  ChoirApp.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//
import SwiftUI

@main
struct ChoirApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var backgroundMonitor = SceneDelegate()
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            TextSelectionSheetProvider {
                appCoordinator.rootView()
            }
            .environmentObject(appCoordinator.walletManager)
            .environmentObject(appCoordinator.authService)
            .environmentObject(appDelegate)
            .environmentObject(backgroundMonitor)
            .onAppear {
                print("App appeared - checking authentication state")

                // Check biometric authentication availability
                let keychain = KeychainService()
                if keychain.canUseBiometricAuthentication() {
                    print("Biometric authentication available: \(keychain.biometricType())")
                } else {
                    print("Biometric authentication not available, using passcode fallback")
                }
            }
            .onChange(of: appCoordinator.currentAuthState) { newState in
                print("Auth state changed to \(newState)")
            }
        }
    }
}
