//
//  ContentView.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ChorusViewModel
    @State private var threads: [ChoirThread] = []
    @State private var selectedChoirThread: ChoirThread?
    @State private var showingWallet = false

    init() {
        _viewModel = StateObject(wrappedValue: ChorusViewModel(coordinator: RESTChorusCoordinator()))
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
                Text("Select a thread")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingWallet) {
            WalletView()
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
