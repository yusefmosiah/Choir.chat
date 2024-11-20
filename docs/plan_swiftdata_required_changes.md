# Updated SwiftData Implementation Plan Checklist

## Overview

Implement SwiftData integration with proper modeling of `ChorusResult`, ensuring users can view all chorus phases of AI responses in their old messages. The plan is broken into chunks, each resulting in a working code checkpoint.

---

## **Chunk 1: Introduce SwiftData with Basic Models and Persistence**

### Goals

- Set up SwiftData in the project.
- Create basic SwiftData models (`CHUser`, `CHThread`, `CHMessage`).
- Ensure data persistence between app launches.
- Integrate wallet management with `CHUser`.

### Checklist

- **Set Up SwiftData**
  - [ ] Configure the SwiftData stack (`ModelContainer`, `ModelContext`).
  - [ ] Ensure SwiftData is ready to use with the new models.

- **Create Basic SwiftData Models**

  - **`CHUser` Model**
    - [ ] Properties:
      - [ ] `walletAddress` (String): Unique identifier from `wallet.accounts[0].address()`.
      - [ ] `createdAt` (Date).
    - [ ] Relationships:
      - [ ] `ownedThreads` (to-many `CHThread`).
      - [ ] `messages` (to-many `CHMessage`).

  - **`CHThread` Model**
    - [ ] Properties:
      - [ ] `id` (UUID): Unique identifier.
      - [ ] `title` (String).
      - [ ] `createdAt` (Date).
    - [ ] Relationships:
      - [ ] `owner` (to-one `CHUser`).
      - [ ] `messages` (to-many `CHMessage`).

  - **`CHMessage` Model**
    - [ ] Properties:
      - [ ] `id` (UUID): Unique identifier.
      - [ ] `content` (String).
      - [ ] `timestamp` (Date).
      - [ ] `isUser` (Bool).
    - [ ] Relationships:
      - [ ] `author` (to-one `CHUser`).
      - [ ] `thread` (to-one `CHThread`).

- **Integrate `WalletManager` with `CHUser`**
  - [ ] After wallet creation/loading, create or load a `CHUser` using the wallet address.
  - [ ] Store the `CHUser` instance for access throughout the app.

- **Implement Data Persistence**
  - [ ] Ensure data for `CHUser`, `CHThread`, and `CHMessage` is persisted using SwiftData.
  - [ ] Test data persistence between app launches.

---

## **Chunk 2: Model `ChorusResult` and Integrate with Messages**

### Goals

- Create a `ChorusResult` model to store all phases of AI responses.
- Update `CHMessage` to include a relationship to `ChorusResult`.
- Ensure AI responses with all chorus phases are properly stored and retrievable.

### Checklist

- **Create `ChorusResult` Model**
  - [ ] Properties:
    - [ ] `id` (UUID): Unique identifier.
    - [ ] `phases` (Dictionary or appropriate data structure to store phase content).

- **Update `CHMessage` Model**
  - [ ] Add relationship to `ChorusResult` (`chorusResult`).

- **Modify `ChorusViewModel`**
  - [ ] Update to work with `CHMessage` and `ChorusResult`.
  - [ ] Store the full `ChorusResult` with all phases when processing a message.

- **Update Storage Logic**
  - [ ] Ensure `ChorusResult` is saved with the AI's `CHMessage`.

- **Adjust UI to Display Chorus Phases**
  - [ ] Modify views to display all chorus phases associated with a message.
  - [ ] Ensure users can view old messages with all their chorus phases.

---

## **Chunk 3: Replace Old Models and Update UI**

### Goals

- Replace `ChoirThread` and `Message` models with `CHThread` and `CHMessage`.
- Update views to use new models.
- Implement `ThreadListViewModel` and `ThreadDetailViewModel`.

### Checklist

- **Implement `ThreadListViewModel`**
  - [ ] Manage fetching and displaying the list of threads.
  - [ ] Handle creating new threads.

- **Implement `ThreadDetailViewModel`**
  - [ ] Manage message fetching and sending within a thread.
  - [ ] Handle AI processing and storing `ChorusResult`.

- **Update `ContentView.swift`**
  - [ ] Replace `threads: [ChoirThread]` with data from SwiftData.
  - [ ] Use `ThreadListViewModel`.
  - [ ] Adjust navigation to pass selected `CHThread` to detail view.

- **Rename and Update `ChoirThreadDetailView.swift` to `ThreadDetailView.swift`**
  - [ ] Replace `ChoirThread` with `CHThread`.
  - [ ] Use `ThreadDetailViewModel`.
  - [ ] Update message display to use `CHMessage`.

- **Update Other Views**
  - **`MessageRow.swift`**
    - [ ] Update to accept `CHMessage`.
    - [ ] Adjust bindings to match `CHMessage` properties.
    - [ ] Display author information and chorus phases.

- **Remove Old Models**
  - [ ] Delete `ChoirThread.swift` and related old models.
  - [ ] Update all references to use `CHThread`.

---

## **Chunk 4: Implement Prior Support and Navigation**

### Goals

- Enhance `CHMessage` to include prior references.
- Implement navigation to source threads and messages from priors.
- Ensure the Experience phase displays priors and allows navigation.

### Checklist

- **Update `CHMessage` Model**
  - [ ] Add a relationship for prior references (`priors`).

- **Modify AI Processing to Store Priors**
  - [ ] Save priors returned from the Experience phase.
  - [ ] Link priors to the AI's `CHMessage`.

- **Update UI to Display Priors**
  - [ ] Display priors in the Experience phase view.

- **Implement Navigation to Priors**
  - [ ] Allow users to navigate to prior messages and threads.

---

## **Chunk 5: Finalize and Refine**

### Goals

- Test the entire application thoroughly.
- Refine the UI and user experience.
- Fix any bugs or issues.

### Checklist

- **Comprehensive Testing**
  - [ ] Test all features end-to-end.
  - [ ] Ensure data integrity and persistence.

- **Optimize Performance**
  - [ ] Review and optimize data fetches and UI updates.
  - [ ] Ensure smooth performance.

- **Polish UI**
  - [ ] Refine UI elements for better user experience.
  - [ ] Ensure consistent styling and responsiveness.

- **Documentation and Code Cleanup**
  - [ ] Comment code where necessary.
  - [ ] Remove unused code or resources.
  - [ ] Update documentation to reflect changes.

---

# Notes

- **Working Checkpoints**: After each chunk, ensure the app is functional.
- **Testing**: Continuously test at each stage.
- **User Experience**: Prioritize intuitive usage.
- **Modeling `ChorusResult`**: Enhances value by allowing access to all chorus phases.
- **Incremental Development**: Breaking into chunks allows manageable progress.
