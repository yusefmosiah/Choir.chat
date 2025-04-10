# Unified Navigation Implementation Plan (Revised)

---

## Overview

Implement unified navigation (tap-to-page, swipe-to-phase) by **centralizing gesture handling within `PostchainView`** using transparent overlays, avoiding the need for a new container view.

---

## Why This Approach?

- **Simpler:** Leverages existing `PostchainView` structure.
- **Avoids Conflicts:** No overlapping gestures on individual phase cards.
- **Centralized Logic:** Navigation decisions happen in one place.
- **Clear Separation:**
    - `PaginatedMarkdownView`: Renders content, handles link taps.
    - `PhaseCard`: Displays phase content, passes state.
    - `PostchainView`: Manages phase stack, handles navigation gestures (tap/swipe).

---

## High-Level Architecture

```mermaid
graph TD
    A[PostchainView] --> B{ZStack of PhaseCards};
    A --> C[Tap Overlays (Left/Right)];
    A --> D[Drag Gesture (Swipe)];

    C -- Tap --> E[handleTap()];
    D -- Swipe --> F[switchToPhase()];

    E --> G{Update currentPage / Call switchToPhase()};
    F --> H[Update selectedPhase & currentPage];

    B --> I[PhaseCard];
    I --> J[PaginatedMarkdownView];

    J -- Updates --> K((Message State: phaseTotalPages));
    E -- Reads --> L((Message State: currentPage, totalPages));
    G -- Updates --> M((Message State: currentPage));
    H -- Updates --> N((Message State: selectedPhase, currentPage));

    style K fill:#lightgrey,stroke:#333,stroke-width:2px;
    style L fill:#lightgrey,stroke:#333,stroke-width:2px;
    style M fill:#lightgrey,stroke:#333,stroke-width:2px;
    style N fill:#lightgrey,stroke:#333,stroke-width:2px;
```

---

## Step-by-Step Implementation Plan

### 1. **Expose `totalPages` (State Management)**

- **`Message` Model (`ConversationModels.swift`):**
    - Add `@Published var phaseTotalPages: [Phase: Int] = [:]`

- **`PaginatedMarkdownView` (`PaginatedMarkdownView.swift`):**
    - Add `@Binding var totalPages: Int`
    - In `paginateContent()`, update this binding: `totalPages = pages.count`

- **`PhaseCard` (`PhaseCard.swift`):**
    - When creating `PaginatedMarkdownView`, pass the new binding:
      ```swift
      PaginatedMarkdownView(
          // ... other params
          totalPages: Binding<Int>(
              get: { message.phaseTotalPages[phase] ?? 1 },
              set: { message.phaseTotalPages[phase] = $0 }
          )
          // ... other params
      )
      ```

---

### 2. **Modify `PostchainView` (`PostchainView.swift`)**

- **Remove `.onTapGesture` from `PhaseCard`:**
    - Delete the `.onTapGesture` modifier within the `ForEach` loop creating `PhaseCard`s.

- **Keep Existing `DragGesture`:**
    - The swipe gesture attached to the `ZStack` remains.

- **Add Tap Overlays:**
    - Inside the `GeometryReader`, overlay the `ZStack` with transparent tap zones:
      ```swift
      ZStack {
          // ... ForEach loop for PhaseCards ...
      }
      .gesture(
          // ... Existing DragGesture ...
      )
      .overlay(
          HStack(spacing: 0) {
              Color.clear.contentShape(Rectangle()).onTapGesture { handleTap(isRightTap: false) }
              Color.clear.contentShape(Rectangle()).onTapGesture { handleTap(isRightTap: true) }
          }
      )
      ```

- **Implement `handleTap` Logic:**
    - Add a private function:
      ```swift
      private func handleTap(isRightTap: Bool) {
          guard let currentPhase = selectedPhase else { return }
          let currentPage = message.phaseCurrentPage[currentPhase] ?? 0
          let totalPages = message.phaseTotalPages[currentPhase] ?? 1

          withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              if isRightTap {
                  if currentPage < totalPages - 1 {
                      message.phaseCurrentPage[currentPhase] = currentPage + 1
                  } else {
                      switchToPhase(direction: .next) // Assumes helper exists
                  }
              } else {
                  if currentPage > 0 {
                      message.phaseCurrentPage[currentPhase] = currentPage - 1
                  } else {
                      switchToPhase(direction: .previous) // Assumes helper exists
                  }
              }
          }
      }
      ```
- **Verify `switchToPhase` Helper:**
    - Ensure this function (likely already present for swipe) correctly resets `currentPage` when changing phases (e.g., to 0 for next, `totalPages - 1` for previous).

---

### 3. **Deep Link Previews (Orthogonal)**

- Continue to intercept `.onOpenURL` **inside `PaginatedMarkdownView`**.
- Implement the **translucent modal preview** logic there. This is separate from the navigation gesture implementation.

---

## Summary

- State (`totalPages`) flows up from content view to model.
- Gestures (tap overlays, swipe) handled centrally in `PostchainView`.
- Tap logic reads state (`currentPage`, `totalPages`) to decide action.
- `PhaseCard` focuses on rendering.

---

_Last updated: April 10, 2025_
