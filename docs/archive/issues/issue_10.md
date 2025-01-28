# Thread Sheet Implementation

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Design and implement the thread sheet UI with a focus on human experience, incorporating the carousel UI pattern for phase navigation and ensuring smooth interaction flows.

## Tasks

### 1. Core UI Components
```swift
struct ThreadSheet: View {
    @ObservedObject var thread: ChoirThread
    @StateObject var viewModel: ThreadViewModel

    var body: some View {
        VStack {
            // Header with thread info
            ThreadHeaderView(thread: thread)

            // Carousel for phase navigation
            ChorusCarouselView(viewModel: viewModel)
                .frame(maxHeight: .infinity)

            // Message input
            MessageInputView(onSend: { message in
                Task { await viewModel.send(message) }
            })
        }
    }
}
```

### 2. Phase Navigation
```swift
struct PhaseView: View {
    let phase: Phase
    @ObservedObject var viewModel: ThreadViewModel

    var body: some View {
        VStack(spacing: 20) {
            // Current phase content
            PhaseContentView(phase: phase, content: viewModel.currentContent)

            // Peek at adjacent phases
            if let nextContent = viewModel.nextPhasePreview {
                Text(nextContent)
                    .font(.caption)
                    .opacity(0.6)
            }
        }
        .transition(.slide)
    }
}
```

### 3. Loading States
- Implement progressive loading indicators
- Show phase transitions smoothly
- Handle network delays gracefully

## Success Criteria
- Intuitive navigation between phases
- Clear visibility of process flow
- Smooth animations and transitions
- Responsive user feedback
