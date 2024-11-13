//
//  ContentView.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ChorusViewModel
    @State private var threads: [Thread] = []
    @State private var selectedThread: Thread?

    init() {
        // #if DEBUG
        // _viewModel = StateObject(wrappedValue: ChorusViewModel(coordinator: MockChorusCoordinator()))
        // #else
        _viewModel = StateObject(wrappedValue: ChorusViewModel(coordinator: RESTChorusCoordinator()))
        // #endif
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar - Thread List
            List(threads, selection: $selectedThread) { thread in
                NavigationLink(value: thread) {
                    ThreadRow(thread: thread)
                }
            }
            .navigationTitle("Threads")
            .toolbar {
                Button(action: createNewThread) {
                    Label("New Thread", systemImage: "plus")
                }
            }
        } detail: {
            // Detail - Thread Messages or Chorus Response
            if let thread = selectedThread {
                ThreadDetailView(thread: thread, viewModel: viewModel)
            } else {
                Text("Select a thread")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func createNewThread() {
        let thread = Thread() // Uses auto-generated title
        threads.append(thread)
        selectedThread = thread
    }
}

struct ThreadRow: View {
    @ObservedObject var thread: Thread

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
