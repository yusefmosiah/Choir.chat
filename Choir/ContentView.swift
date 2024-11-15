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

    init() {
        // #if DEBUG
        // _viewModel = StateObject(wrappedValue: ChorusViewModel(coordinator: MockChorusCoordinator()))
        // #else
        _viewModel = StateObject(wrappedValue: ChorusViewModel(coordinator: RESTChorusCoordinator()))
        // #endif
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar - ChoirThread List
            List(threads, selection: $selectedChoirThread) { thread in
                NavigationLink(value: thread) {
                    ChoirThreadRow(thread: thread)
                }
            }
            .navigationTitle("ChoirThreads")
            .toolbar {
                Button(action: createNewChoirThread) {
                    Label("New ChoirThread", systemImage: "plus")
                }
            }
        } detail: {
            // Detail - ChoirThread Messages or Chorus Response
            if let thread = selectedChoirThread {
                ChoirThreadDetailView(thread: thread, viewModel: viewModel)
            } else {
                Text("Select a thread")
                    .foregroundStyle(.secondary)
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
