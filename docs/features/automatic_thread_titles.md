**Status:** Implemented on 2025-04-09

# Feature Plan: Automatic Thread Titles

**Goal:** Implement a mechanism to automatically generate titles for new Choir threads based on the first 10 words of the AI's "Action" phase response in the initial message, without overwriting manually set titles.
**This feature is now live.** Choir threads automatically receive a generated title based on the first 10 words of the initial AI Action phase response, unless the user manually sets a title.


**Implementation Strategy:** Client-Side

**Detailed Steps:**

1.  **Trigger Location:** Modify the logic within the `RESTPostchainCoordinator` (or potentially `PostchainViewModel`) where Server-Sent Events (SSE) are handled.
2.  **Identify Action Phase Completion:** Detect the SSE event where `phase == "action"` and `status == "complete"`.
3.  **Add Detection Logic:**
    *   When the `Action` phase completion event arrives:
        *   Check if the message being updated is the *first AI message* in the thread (e.g., check `thread.messages.count == 2` and the message `isUser == false`).
        *   Check if the current thread title still matches the default "ChoirThread [timestamp]" pattern (using a regex or prefix check). This prevents overwriting manually set titles.
4.  **Extract & Generate Title:**
    *   If all conditions are met:
        *   Retrieve the *complete* `Action` phase content from the `Message` object (it should be fully populated by this point).
        *   Implement a helper function `String.prefixWords(10)` (likely as a String extension) to get exactly the first 10 words. Handle potential edge cases like fewer than 10 words.
        *   Generate the title: `let generatedTitle = fullActionContent.prefixWords(10)`.
        *   If `generatedTitle` is empty, use a fallback: `let finalTitle = generatedTitle.isEmpty ? "New Thread" : generatedTitle`.
5.  **Update Thread Title:**
    *   Call `thread.updateTitle(finalTitle)` on the corresponding `ChoirThread` object. The existing persistence logic within `updateTitle` will handle saving.

**Sequence Diagram:**

```mermaid
sequenceDiagram
    participant User
    participant ContentView
    participant ChoirThreadDetailView
    participant PostchainViewModel
    participant RESTPostchainCoordinator
    participant BackendAPI

    User->>ContentView: Taps "New Thread"
    ContentView->>ContentView: createNewChoirThread()
    Note right of ContentView: Creates ChoirThread() with default title
    ContentView->>ChoirThreadDetailView: Navigates with new thread
    User->>ChoirThreadDetailView: Enters first message & taps "Send"
    ChoirThreadDetailView->>ChoirThreadDetailView: sendMessage("User query")
    Note right of ChoirThreadDetailView: Adds User Message & AI Placeholder Message
    ChoirThreadDetailView->>PostchainViewModel: process("User query")
    PostchainViewModel->>RESTPostchainCoordinator: Start SSE stream request
    RESTPostchainCoordinator->>BackendAPI: POST /postchain
    BackendAPI-->>RESTPostchainCoordinator: SSE Stream Start
    loop For Each Phase Chunk/Event
        BackendAPI-->>RESTPostchainCoordinator: SSE Event (phase, status, content chunk)
        RESTPostchainCoordinator->>PostchainViewModel: Handle SSE Event
        PostchainViewModel->>Message: Update phase content (accumulating)
        alt Event is Action Phase Completion
            PostchainViewModel->>PostchainViewModel: isActionPhase? Yes. isComplete? Yes.
            PostchainViewModel->>PostchainViewModel: isFirstAIMessage? Yes. isDefaultTitle? Yes.
            PostchainViewModel->>Message: getPhaseContent(.action) (Full content)
            PostchainViewModel->>String: fullActionContent.prefixWords(10)
            PostchainViewModel->>ChoirThread: updateTitle("First 10 words...")
            Note right of PostchainViewModel: Title updated, UI refreshes
        end
    end
    BackendAPI-->>RESTPostchainCoordinator: SSE Stream End
```

**Key Decisions:**
*   Update title only after the *entire* Action phase is complete.
*   Do *not* overwrite manually edited titles.
*   Use *exactly* the first 10 words, without filtering filler words for this initial version.
