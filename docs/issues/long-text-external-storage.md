Issue Ticket: Implement External File Storage for Long Messages

Task ID: long-text-external-storage-01

Assigned To: AI Coding Worker

Priority: High

Description:

Currently, messages with content longer than 4000 characters are truncated in the UI (MessageRow) but the full content is saved within the main thread JSON file. This task is to modify the system to save the full content of these "long messages" to separate text files and update the thread loading/saving logic and UI accordingly.

Current Behavior:
MessageRow.swift checks message.content.count > 4000 and displays a truncated preview <long_text>...</long_text>. The full message.content is saved in the thread's JSON file.

Desired Behavior:

Messages with content.count > 4000 should have their full content saved to a separate .txt file.

The main thread file should store a reference to this external file for the corresponding message, instead of the full content.

When a thread is loaded, the content from these external files should be read back into the respective Message objects in memory ("multi-step retrieval").

The MessageRow UI should display a distinct "block" element for messages whose content is stored externally.

Tapping this "block" element should reveal the full text using the existing TextSelectionSheet.

Acceptance Criteria:

Persistence (ThreadPersistenceService.swift):

When saveThread is called, any Message within the thread where content.count > 4000 must:

Have its full content written to a plain text file named [message.id].txt inside a LongTexts/ subdirectory within the application's Documents directory.

Have its externalContentRef property (see Data Model Changes) set to the filename ([message.id].txt).

Have its content property (as saved in the thread JSON) set to an empty string or a placeholder like "[external]".

Messages with content.count <= 4000 should be saved as they are currently (full content inline, externalContentRef is nil).

Loading (ThreadPersistenceService.swift):

When loadThread (or loadAllThreads) is called:

The main thread JSON is loaded.

For each Message where externalContentRef is not nil:

The corresponding file (LongTexts/[externalContentRef]) must be read.

The content read from the file must be assigned to the message.content property in the in-memory Message object.

If the file is missing or cannot be read, the message.content property should be set to "[Error loading text]".

Data Model (ChoirModels.swift):

The Message class must be updated to include a new optional property: var externalContentRef: String?.

The Message class initializer and Codable conformance must be updated to handle this new property.

UI Display (MessageRow.swift):

The logic within MessageRow must be updated:

Instead of checking message.content.count > 4000, it should check if message.externalContentRef != nil.

If message.externalContentRef != nil, display a distinct UI element (e.g., a gray rounded rectangle containing Text("[Long Text - Tap to View]").italic()).

The existing else block (displaying Text(LocalizedStringKey(message.content))) should handle messages where externalContentRef == nil.

UI Interaction (MessageRow.swift):

The new UI element for external long text must have a .onTapGesture modifier.

The tap gesture must call TextSelectionManager.shared.showSheet(withText: message.content). This requires the full content to have been loaded into message.content by the persistence service.

Implementation Details/Hints:

Modify ThreadPersistenceService.swift for saving and loading logic. Ensure file operations are handled correctly (creating the LongTexts/ directory if needed, reading/writing files). Use FileManager to get the Documents directory URL.

Modify ChoirModels.swift to update the Message class.

Modify MessageRow.swift to implement the new UI representation and tap gesture.

The threshold remains 4000 characters.

This change applies only to messages saved after this implementation. No migration of existing data is required for this task.

Files to Potentially Modify:

Choir/Services/ThreadPersistenceService.swift

Choir/Models/ChoirModels.swift (specifically the Message class)

Choir/Views/MessageRow.swift

Considerations:

Performance: Loading all long texts upfront when a thread loads might be slow for threads with many long messages. This is acceptable for the initial implementation per the requirements, but flag for potential future optimization (lazy loading).

Error Handling: Ensure robust error handling for file read/write operations and missing files during loading.

Thread Safety: File operations in ThreadPersistenceService should ideally be performed on a background thread to avoid blocking the main thread, especially during loading.