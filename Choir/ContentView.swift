//
//  ContentView.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var walletManager: WalletManager
    @StateObject private var viewModel: PostchainViewModel
    @State private var threads: [ChoirThread] = []
    @State private var selectedChoirThread: ChoirThread?
    @State private var showingWallet = false

@State private var userUUID: String? = nil
@AppStorage("userUUID") private var storedUserUUID: String = ""

    init() {
        _viewModel = StateObject(wrappedValue: PostchainViewModel(coordinator: RESTPostchainCoordinator()))
    }

    var body: some View {
        NavigationSplitView {
            List(threads, selection: $selectedChoirThread) { thread in
                NavigationLink(value: thread) {
                    ChoirThreadRow(thread: thread)
                }
            }
            .navigationTitle("ChoirThreads")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { // Explicit placement for the primary action
                    Button { // Change to async task execution
                        Task {
                            await createNewChoirThread()
                        }
                    } label: {
                        Label("New ChoirThread", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) { // Keep explicit placement for leading item
                    Button(action: { showingWallet = true }) {
                        Label("Wallet", systemImage: "wallet.pass")
                    }
                }
            }
        } detail: {
            if let thread = selectedChoirThread {
                ChoirThreadDetailView(thread: thread, viewModel: viewModel)
            } else {
                VStack(spacing: 20) {
                    Text("Choir")
                        .font(.largeTitle)
                        .bold()

                    Image("Icon-App-1024x1024")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                        .opacity(0.7)

                    Text("Select a thread or create a new one")
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)

                    Button { // Change to async task execution
                        Task {
                            await createNewChoirThread()
                        }
                    } label: {
                        Label("Create New Thread", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary.opacity(0.1))
            }
        }
        .sheet(isPresented: $showingWallet) {
            WalletView()
        }
        .onAppear {
            Task {
                do {
                    if walletManager.wallet == nil {
                        try await walletManager.createOrLoadWallet()
                        print("Wallet loaded successfully")
                    }

                    guard let wallet = walletManager.wallet else {
                        print("Failed to load wallet")
                        return
                    }

                    if !storedUserUUID.isEmpty {
                        print("Using stored user UUID: \(storedUserUUID)")
                        userUUID = storedUserUUID
                    } else {
                        let suiAddress = (try? wallet.accounts[0].publicKey.toSuiAddress()) ?? ""

                        let challengeURL = ChoirAPIClient.shared.baseURL.appendingPathComponent("/auth/request_challenge")
                        var challengeRequest = URLRequest(url: challengeURL)
                        challengeRequest.httpMethod = "POST"
                        challengeRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        let challengeBody = ["address": suiAddress]
                        challengeRequest.httpBody = try JSONEncoder().encode(challengeBody)

                        let (challengeData, _) = try await URLSession.shared.data(for: challengeRequest)
                        let challengeResponse = try JSONDecoder().decode([String: String].self, from: challengeData)
                        let challenge = challengeResponse["challenge"] ?? ""

                        // Check if we already have a UUID for this address to avoid unnecessary verification
                        if let cachedUUID = ChoirAPIClient.shared.getCachedUserId(for: suiAddress) {
                            print("Using cached UUID for Sui address: \(suiAddress)")
                            userUUID = cachedUUID
                            storedUserUUID = cachedUUID
                        } else {
                            // 2. Sign challenge (mocked)
                            let signature = "MOCK_SIGNATURE_BASE64"

                            // 3. Verify user, get UUID
                            let uuid = try await ChoirAPIClient.shared.verifyUser(address: suiAddress, signature: signature)
                            userUUID = uuid
                            storedUserUUID = uuid

                            print("Generated new UUID for Sui address: \(suiAddress) -> \(uuid)")
                        }
                    }

                    // 4. Fetch threads using UUID
                    let threadResponses = try await ChoirAPIClient.shared.fetchUserThreads(userId: userUUID ?? storedUserUUID)
                    let loadedThreads = threadResponses.map { response in
                        let thread = ChoirThread(
                            id: UUID(uuidString: response.id) ?? UUID(),
                            title: response.name
                        )
                        return thread
                    }
                    threads = loadedThreads
                    if selectedChoirThread == nil, let first = loadedThreads.first {
                        selectedChoirThread = first
                    }
                } catch {
                    print("Error during auth or fetching threads: \(error)")
                }
            }
        }
    }

    private func createNewChoirThread() async {
        // Assign the result of nil-coalescing first, then check if it's empty
        let potentialUserId = userUUID ?? storedUserUUID
        guard !potentialUserId.isEmpty else {
            print("❌ Error: Cannot create thread without a user UUID.")
            // Optionally show an alert to the user
            return
        }

        // Generate a default name
        let defaultName = "ChoirThread \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"

        // We know potentialUserId is non-empty here from the guard statement. Use it directly.
        print("🚀 Creating new thread on backend for user \(potentialUserId)...")
        do {
            let createdThreadResponse = try await ChoirAPIClient.shared.createThread(
                name: defaultName,
                userId: potentialUserId // Use potentialUserId directly
                // initialMessage: nil // No initial message when creating from list view
            )

            print("✅ Backend thread created with ID: \(createdThreadResponse.id)")

            // Create the local ChoirThread object using data from the backend response
            let newThread = ChoirThread(
                id: UUID(uuidString: createdThreadResponse.id) ?? UUID(), // Use ID from backend
                title: createdThreadResponse.name // Use name from backend
            )

            // Update UI on main thread
            await MainActor.run {
                threads.append(newThread)
                selectedChoirThread = newThread
                print("✅ Local thread object created and selected.")
            }

        } catch {
            print("❌ Error creating thread via API: \(error)")
            // Optionally show an error alert to the user
        }
    }
}

struct ChoirThreadRow: View {
    @ObservedObject var thread: ChoirThread

    var body: some View {
        VStack(alignment: .leading) {
            Text(thread.title)
                .font(.headline)
            Text("\(thread.messages.count) messages")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
