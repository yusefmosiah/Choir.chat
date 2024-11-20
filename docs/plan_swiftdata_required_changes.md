# SwiftData Required Changes Checklist

## Summary of Required Actions

### Update Existing Code to Use New Models
- [ ] Replace `ChoirThread` with `CHThread`.
- [ ] Replace `Message` with `CHMessage`.
- [ ] Ensure all data relationships align with the new SwiftData models.

### Implement New ViewModels
- [ ] Create `ThreadListViewModel` and integrate it into `ContentView.swift`.
- [ ] Create `ThreadDetailViewModel` and integrate it into `ThreadDetailView.swift`.

### Adjust `WalletManager.swift`
- [ ] After wallet creation/loading, create or load a `CHUser` using the wallet address.
- [ ] Ensure that `CHUser` is accessible throughout the app for authoring messages and threads.

### Modify Views and Coordinators
- [ ] Update views to use new models and view models.
- [ ] Adjust coordinators to handle new data models and any changes in data flow.

## Code Files Requiring Changes

### `WalletManager.swift`
- [ ] Instantiate or load a `CHUser` object using the wallet's address after wallet creation or loading.
- [ ] Use the wallet's address as the unique identifier for the `CHUser`.
- [ ] Adjust methods to reflect the association between `Wallet` and `CHUser`.

### `ChorusViewModel.swift`
- [ ] Modify to work with the new `CHMessage` model instead of the old `Message` struct.
- [ ] Update data fetching or state management to align with `CHThread` and `CHMessage`.

### `ContentView.swift`
- [ ] Replace `threads: [ChoirThread]` with a `ThreadListViewModel` instance.
- [ ] Update thread creation to use `CHThread`, setting the current `CHUser` as the owner.
- [ ] Adjust navigation links and views to work with `CHThread` and associated view models.

### `ChoirThreadDetailView.swift`
- [ ] Rename to `ThreadDetailView.swift` for consistency.
- [ ] Replace `ChoirThread` with `CHThread`.
- [ ] Use `ThreadDetailViewModel` to manage state and interactions.
- [ ] Update message display to use `CHMessage`.

### `MessageRow.swift`
- [ ] Update to accept `CHMessage` instead of `Message`.
- [ ] Adjust bindings and property references to match the new model's properties.
- [ ] Display author information using `CHMessage.author`.

### `ChorusCoordinator.swift` and `RESTChorusCoordinator.swift`
- [ ] Modify references to `ChoirThread` and `Message` to use `CHThread` and `CHMessage`.
- [ ] Ensure thread and message IDs align with the new models.
- [ ] Update functions that pass thread or message data to the API.

### `ChorusModels.swift`
- [ ] Review for conflicts with the new `CHMessage` model.
- [ ] Remore Message definition
- [ ] Adjust models if necessary to ensure compatibility with SwiftData models.

### `ChorusResponse.swift` and `ChorusCycleView.swift`
- [ ] Verify if they interact with `Message` or `ChoirThread` and update references to `CHMessage` or `CHThread` if needed.

## New Files to Be Created

### Models/Core/
- [ ] `CHUser.swift`: SwiftData model for `CHUser`, using wallet address as the unique identifier.
- [ ] `CHThread.swift`: SwiftData model for `CHThread`, representing threads owned and co-authored by users.
- [ ] `CHMessage.swift`: SwiftData model for `CHMessage`, including content, timestamp, author, and thread relationships.

### ViewModels/
- [ ] `ThreadListViewModel.swift`: Manages the list of threads for the current user. Handles loading, creating, and selecting threads.
- [ ] `ThreadDetailViewModel.swift`: Manages the state and interactions within a thread. Handles loading messages, sending messages, and AI processing.

### Views/
- [ ] `ThreadDetailView.swift` (if renamed from `ChoirThreadDetailView.swift`): Updated view to work with `ThreadDetailViewModel` and the new models.
- [ ] Any additional view files needed to support the new models and view models.

## Files to Be Deleted or Deprecated

### `ChoirThread.swift`
- [ ] Replace with the new `CHThread` SwiftData model. Update all references to use `CHThread`.

### Test Files Related to Old Models
- [ ] `ChoirThreadTests.swift`: Update or replace with tests for `CHThread`.
- [ ] `APIResponseTests.swift` and `ChorusAPIClientTests.swift`: Review and update if they rely on the old models.
