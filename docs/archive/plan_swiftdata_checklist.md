# SwiftData Implementation Checklist

## Objective

Implement data persistence in the Choir app using SwiftData, updating the existing code to align with the revised data model which treats AI responses as part of `ChorusResult` linked to user messages. Update all call sites where `chorusresult` is currently used to reflect these changes, considering that `ChoirThreadDetailView` uses `ChorusViewModel`.

---

## Updated Checklist

### **1. Update Data Models**

- [ ] **Create `CoreDataModels.swift`**
  - Create new file to contain all SwiftData models.
  - Include complete model hierarchy:
    ```swift
    // User model
    @Model class User { }

    // Thread model
    @Model class Thread { }

    // Message model
    @Model class Message { }

    // ChorusResult model
    @Model class ChorusResult { }

    // ChorusPhase model
    @Model class ChorusPhase { }

    // PhaseType enum
    enum PhaseType { }
    ```
  - Define all relationships between models.
  - Include proper delete rules for cascading deletions.
  - Add documentation comments for each model.

- [ ] **Deprecate Existing Model Files**
  - Mark `ChoirThread.swift` as deprecated.
  - Mark `ChorusModels.swift` as deprecated.
  - Plan removal after migration is complete.

### **2. Configure SwiftData ModelContainer**

- [ ] Include all updated models in the `ModelContainer` within `ChoirApp.swift`.

### **3. Update Data Migration Logic**

- [ ] Adjust any existing migration scripts to align with the new data models.
  - Ensure that historical data is migrated properly.
  - Map old `chorusresult` usages to the new model structure.

### **4. Modify ViewModels**

- [ ] **Update `ChorusViewModel`**
  - Ensure it interacts correctly with the new data model.
  - Adjust any references to `chorusresult` to match the updated models.
  - Update the `process` function to return `ChorusResult`.
  - Modify state management to align with the new data structures.

### **5. Update Views**

#### **5.1 Modify `ContentView`**

- [ ] Update to use a `ThreadListViewModel` (if necessary) with persisted threads.
  - If you don't have a `ThreadListViewModel`, incorporate SwiftData's `@Query` property wrappers in `ContentView`.

#### **5.2 Modify `ChoirThreadDetailView`**

- [ ] Display messages and associated AI responses from `ChorusResult`.
  - Update UI to display the AI response embedded within the user's message.
  - Remove any logic that treats AI responses as separate messages.
  - Adjust bindings to work with the updated `ChorusViewModel`.

#### **5.3 Update `MessageRow`**

- [ ] Adjust to display the AI response within the `ChorusResult` linked to the user message.
  - Remove any handling of `isUser` flag.
  - Display AI response along with the user's message in a unified view.
  - Ensure that the chorus cycle visualization (`ChorusCycleView`) is correctly linked to the `ChorusResult`.

#### **5.4 Adjust Other Views as Necessary**

- [ ] Review and update any other views that reference `chorusresult`, `Message`, or related models.

### **6. Update Chorus Coordinator**

- [ ] Modify `ChorusCoordinator` to return data compatible with the new models.
  - Ensure it populates `ChorusResult` and `ChorusPhase` appropriately.
  - Adjust protocol definitions and implementations.

### **7. Update Call Sites of `chorusresult`**

#### **7.1 In `Choir/Models/ChoirThread.swift`**

- [ ] **Update `ChoirThread`**

  - Ensure that `messages` only contains user `Message` instances.
  - Remove references to AI messages in the `messages` array.
  - Update any logic that aggregates or processes messages.

#### **7.2 In `Choir/Models/ChorusModels.swift`**

- [ ] **Deprecate or Update as Necessary**

  - Since the data model has changed, assess whether this file is still needed.
  - Migrate any necessary types or logic into the updated models.

#### **7.3 In `Choir/Views/ChoirThreadDetailView.swift`**

- [ ] **Update Message Display Logic**

  - Modify how messages are displayed to include both the user message and the associated AI response from `ChorusResult`.
  - Remove any code that adds AI responses as separate messages.
  - Ensure that the view reflects the new data model and interacts properly with `ChorusViewModel`.

#### **7.4 In `Choir/Views/MessageRow.swift`**

- [ ] **Adjust Message Row**

  - Display AI response within the same message bubble or as part of the message UI.
  - Remove handling of `isUser` flag.
  - Update layouts to accommodate the combined user message and AI response.
  - Bind to the updated models.

#### **7.5 In `Choir/ViewModels/ChorusViewModel.swift`**

- [ ] **Update ViewModel Logic**

  - Adjust any references to `chorusresult` to match the updated model.
  - Ensure that the state management aligns with the new data structures.
  - Modify the processing methods to return `ChorusResult` and handle persistence.

#### **7.6 In `Choir/Coordinators/ChorusCoordinator.swift`**

- [ ] **Modify Coordinator Protocol**

  - Update method signatures to reflect changes in data model.
  - Ensure that implementations return data compatible with the new `ChorusResult` model.

#### **7.7 In `ChoirTests/ChoirThreadTests.swift`**

- [ ] **Update Tests**

  - Adjust tests to reflect the new data model and relationships.
  - Ensure that all test cases cover the updated logic.

### **8. Testing**

- [ ] **Data Integrity Testing**

  - Verify that messages and their associated `ChorusResult` are saved and loaded correctly.
  - Ensure that relationships between `Message`, `ChorusResult`, and `ChorusPhase` are correctly established.

- [ ] **Functional Testing**

  - Test the full flow from message input to displaying the AI response.
  - Confirm that the UI updates appropriately with the new model.

- [ ] **Performance Testing**

  - Profile data fetching and saving to ensure there are no performance regressions.
  - Optimize as necessary.

### **9. Performance Optimization**

- [ ] **Optimize Data Fetching**

  - Use appropriate fetch descriptors or predicates to efficiently load messages and related data.
  - Implement lazy loading or pagination if necessary.

- [ ] **Enhance UI Responsiveness**

  - Ensure that UI updates are smooth and do not block the main thread.
  - Use asynchronous operations where appropriate.

### **10. Documentation**

- [ ] **Update Project Documentation**

  - Reflect changes in data models and their relationships.
  - Document any new workflows or architectural decisions.

- [ ] **Add Inline Code Documentation**

  - Use comments to explain complex logic or important considerations in the code.

### **New Section: Model Organization**

- [ ] **Organize Model Relationships**
  - Ensure proper relationship declarations:
    ```swift
    // Example relationship organization
    User
    ├── ownedThreads: [Thread]
    ├── participatedThreads: [Thread]
    └── messages: [Message]

    Thread
    ├── owner: User
    ├── participants: [User]
    └── messages: [Message]

    Message
    ├── author: User
    ├── thread: Thread
    └── chorusResult: ChorusResult?

    ChorusResult
    ├── message: Message
    └── phases: [ChorusPhase]

    ChorusPhase
    ├── chorusResult: ChorusResult
    └── priors: [Message]?
    ```

- [ ] **Document Model Relationships**
  - Create relationship diagram.
  - Document cascade deletion rules.
  - Document optional vs required relationships.

### **Detailed Model Relationships**

```
User (Core Identity)
├── id: UUID [unique, required]
├── walletAddress: String [required]
├── createdAt: Date [required]
├── lastKnownBalance: Double? [optional]
├── lastBalanceUpdate: Date? [optional]
├── ownedThreads: [Thread] [1:many, cascade delete]
├── participatedThreads: [Thread] [many:many]
└── messages: [Message] [1:many, cascade delete]

Thread (Conversation Container)
├── id: UUID [unique, required]
├── title: String [required]
├── createdAt: Date [required]
├── lastActivity: Date [required]
├── owner: User [1:1, required]
├── participants: [User] [many:many]
└── messages: [Message] [1:many, cascade delete]

Message (User Input)
├── id: UUID [unique, required]
├── content: String [required]
├── timestamp: Date [required]
├── author: User [many:1, required]
├── thread: Thread [many:1, required]
└── chorusResult: ChorusResult? [1:1, optional, cascade delete]

ChorusResult (AI Processing Result)
├── id: UUID [unique, required]
├── aiResponse: String [required]
├── totalConfidence: Double [required]
├── processingDuration: TimeInterval? [optional]
├── message: Message [1:1, required]
└── phases: [ChorusPhase] [1:many, cascade delete]

ChorusPhase (Processing Step)
├── id: UUID [unique, required]
├── type: PhaseType [required]
├── content: String [required]
├── confidence: Double [required]
├── reasoning: String? [optional]
├── timestamp: Date [required]
├── shouldYield: Bool? [optional]
├── nextPrompt: String? [optional]
├── chorusResult: ChorusResult [many:1, required]
└── priors: [Message]? [many:many, optional]
```

### **Relationship Rules**

#### Cascade Deletion Rules
- When a `User` is deleted:
  - Delete all owned threads
  - Delete all messages
  - Remove from participated threads

- When a `Thread` is deleted:
  - Delete all messages
  - Remove all participant relationships
  - Keep users intact

- When a `Message` is deleted:
  - Delete associated `ChorusResult` if exists
  - Keep author and thread intact
  - Remove from prior references

- When a `ChorusResult` is deleted:
  - Delete all associated phases
  - Keep message intact

#### Required vs Optional Relationships
- **Required (non-optional)**:
  - User → walletAddress
  - Thread → owner
  - Message → author, thread
  - ChorusResult → message
  - ChorusPhase → chorusResult

- **Optional**:
  - Message → chorusResult
  - ChorusPhase → priors
  - ChorusPhase → shouldYield, nextPrompt

#### Many-to-Many Relationships
- Users ↔ Threads (participation)
- Messages ↔ Messages (priors)

#### One-to-Many Relationships
- User → Messages
- Thread → Messages
- ChorusResult → Phases

#### One-to-One Relationships
- Message ↔ ChorusResult

---

## Notes

- **Ensure Consistency Across the App**

  - Review the entire codebase for any other references to `chorusresult` or related properties.
  - Update all instances to align with the new data model.

- **Maintain Data Integrity**

  - Be cautious with data migrations to avoid data loss.
  - Backup existing data before running migration scripts.

- **User Experience**

  - Test the app thoroughly from a user's perspective to ensure that the changes improve the experience.
  - Solicit feedback if possible.

---

By following this adjusted checklist, we will successfully implement data persistence in the Choir app using SwiftData, aligning the code with the intrinsic logic of the system, and updating all call sites to reflect the changes in how `chorusresult` is used, specifically considering that `ChoirThreadDetailView` uses `ChorusViewModel`.
