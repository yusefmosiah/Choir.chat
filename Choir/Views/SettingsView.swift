import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var walletManager: WalletManager
    @State private var showingLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section(content: {
                    // Account section content
                    if let userInfo = getUserInfo() {
                        HStack {
                            Text("Wallet Address")
                            Spacer()
                            Text(shortenAddress(userInfo.wallet_address))
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Balance")
                        Spacer()
                        if let suiBalance = walletManager.balances[.sui] {
                            Text(suiBalance.formattedBalance)
                                .foregroundColor(.secondary)
                        } else {
                            Text("0.0 SUI")
                                .foregroundColor(.secondary)
                        }
                    }
                }, header: {
                    Text("Account")
                })

                Section(content: {
                    Toggle("Enable Notifications", isOn: .constant(true))
                    Toggle("Dark Mode", isOn: .constant(false))
                }, header: {
                    Text("App Settings")
                })

                Section(content: {
                    NavigationLink(destination: Text("Privacy Policy Content").padding()) {
                        Text("Privacy Policy")
                    }

                    NavigationLink(destination: Text("Terms of Service Content").padding()) {
                        Text("Terms of Service")
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }, header: {
                    Text("About")
                })

                Section {
                    Button(action: {
                        showingLogoutConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Logout")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Logout", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    print("Logout confirmed")
                    authService.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }

    private func getUserInfo() -> UserInfo? {
        if case .authenticated(let userInfo) = authService.authState {
            return userInfo
        }
        return nil
    }

    private func shortenAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }

        let prefix = address.prefix(6)
        let suffix = address.suffix(4)

        return "\(prefix)...\(suffix)"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthService(walletManager: WalletManager()))
            .environmentObject(WalletManager())
    }
}
