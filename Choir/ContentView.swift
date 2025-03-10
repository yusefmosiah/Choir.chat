//
//  ContentView.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: PostchainViewModel
    @State private var threads: [ChoirThread] = []
    @State private var selectedChoirThread: ChoirThread?
    @State private var showingWallet = false

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
                ToolbarItem(placement: .primaryAction) {
                    Button(action: createNewChoirThread) {
                        Label("New ChoirThread", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
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
                    
                    Button(action: createNewChoirThread) {
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
                .background(Color(UIColor.systemBackground))
            }
        }
        .sheet(isPresented: $showingWallet) {
            WalletView()
        }
        .onAppear {
            // Create a default thread if none exists
            if threads.isEmpty {
                createNewChoirThread()
            }
        }
    }

    private func createNewChoirThread() {
        let thread = ChoirThread() // Uses auto-generated title
        threads.append(thread)
        selectedChoirThread = thread
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