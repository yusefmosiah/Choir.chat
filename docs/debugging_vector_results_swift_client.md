# Debugging Guide: Diagnosing Vector Data Handling in the Swift Client

**Goal:**
Identify the specific point of failure in the client-side processing of the `experience_vectors` phase event data.

**Assumption:**
Server logs confirm `vector_results` are being included in the JSON payload for the `experience_vectors` phase event.

**Tools:**
- Xcode Debugger
- `print()` statements in Swift

---

## Approach 1: Deep Dive into Codable Decoding

**Goal:**
Verify if the JSON containing `vector_results` is being successfully decoded into the `PostchainStreamEvent` Swift struct.

**Rationale:**
Mismatches between the JSON structure/types sent by the server and the Swift `Decodable` struct definition (`PostchainStreamEvent` and nested `VectorSearchResult`) will cause decoding to fail, often silently, preventing the data from ever reaching your application logic.

### Steps

1.  **Locate the Decoding Point:**
    Find the exact line(s) in your Swift code where the raw JSON string from the SSE event is decoded into a `PostchainStreamEvent` object. This is likely within `PostchainAPIClient.swift` or a similar networking layer, using `JSONDecoder().decode(...)`.

2.  **Log Raw JSON:**
    Immediately before the decoding attempt, print the raw JSON string received from the event. Specifically capture the JSON for an `experience_vectors` event.

    ```swift
    // Inside your SSE event handler (e.g., in PostchainAPIClient.swift)
    eventSource.onMessage { (id, event, data) in
        print("📬 RAW SSE DATA RECEIVED: \(data ?? "nil")") // Log the raw data string
        guard let dataString = data, let jsonData = dataString.data(using: .utf8) else {
            print("🚨 Error: No data or could not convert to UTF8")
            return
        }
        // ... rest of the decoding logic
    }
    ```

3.  **Inspect Decoder State & Catch Errors:**
    Modify the `init(from decoder: Decoder)` within `PostchainEvent` and `PostchainStreamEvent` (in `APITypes.swift`) to:
    *   Log all keys the decoder recognizes *before* trying to decode `vectorResults`.
    *   Use the more robust `vectorResults` decoding logic (attempting `decodeIfPresent` directly with detailed error catching) that we developed.

    ```swift
    // Inside PostchainEvent/PostchainStreamEvent init(from decoder: Decoder)

    // ... decode other properties ...

    // Log available keys *before* attempting vectorResults
    print("🔑 Decoder Keys Available: \(container.allKeys.map { $0.stringValue })")

    // Attempt to decode vectorResults directly, handling potential errors
    do {
        vectorResults = try container.decodeIfPresent([VectorSearchResult].self, forKey: .vectorResults)
        if let vectors = vectorResults {
             print("🔴 VECTOR: Successfully decoded \(vectors.count) vector results using decodeIfPresent")
             // Optional: Add checks for content as before
        } else {
             print("🔴 VECTOR: decodeIfPresent returned nil for vector_results (key might be missing or value is null)")
             // Explicitly check contains for logging comparison
             if !container.contains(.vectorResults) {
                 print("🔴 VECTOR: Confirmed: container.contains also returns false.")
             } else {
                 print("🔴 VECTOR: Anomaly: container.contains returns true, but decodeIfPresent returned nil. JSON value might be null.")
             }
        }
    } catch let decodingError as DecodingError {
         print("🔴 VECTOR: DecodingError while decoding vectorResults: \(decodingError)")
         // Log detailed context for the decoding error
         switch decodingError {
            case .typeMismatch(let type, let context):
                print("   Type '\(type)' mismatch:", context.debugDescription)
                print("   codingPath:", context.codingPath.map { $0.stringValue })
            case .valueNotFound(let type, let context):
                print("   Value '\(type)' not found:", context.debugDescription)
                print("   codingPath:", context.codingPath.map { $0.stringValue })
            case .keyNotFound(let key, let context):
                print("   Key '\(key)' not found:", context.debugDescription)
                print("   codingPath:", context.codingPath.map { $0.stringValue })
            case .dataCorrupted(let context):
                print("   Data corrupted:", context.debugDescription)
                print("   codingPath:", context.codingPath.map { $0.stringValue })
            @unknown default:
                print("   Other decoding error: \(decodingError)")
         }
         vectorResults = nil // Ensure it's nil on error
    } catch {
        print("🔴 VECTOR: Unexpected error while decoding vectorResults: \(error)")
        vectorResults = nil // Ensure it's nil on error
    }

    // ... rest of init ...
    ```

4.  **Review Swift Structs (`APITypes.swift`, `SearchModels.swift`):**
    *   **`PostchainEvent` / `PostchainStreamEvent`:** Double-check the `CodingKeys` enum ensures `vectorResults` maps to `"vector_results"`.
    *   **`VectorSearchResult`:** Verify its properties (`content`, `score`, `id`, `content_preview`, `metadata`, `provider`) and their `CodingKeys` match the expected JSON structure *within each element* of the `vector_results` array. Pay close attention to optionality (`?`) and data types (`String`, `Double`, `[String: String]?`). Ensure the `metadata` decoding is robust (as implemented previously).

5.  **Run and Analyze:**
    Execute the app (ensure backend is sending full events again), trigger the workflow, and observe the console logs for the `experience_vectors` phase.
    *   Check the `🔑 Decoder Keys Available:` log. Does it include `"vector_results"`?
    *   If `"vector_results"` is missing from the keys, there might be an issue with how the JSON data is being presented to the decoder *before* `init(from:)` is called, or a fundamental issue with the `JSONDecoder` instance.
    *   If the key *is* present, examine the `🔴 VECTOR:` logs. Does `decodeIfPresent` succeed or fail? If it fails, the detailed `DecodingError` context (type mismatch, key not found *within an element*, data corrupted) should pinpoint the exact issue within the `VectorSearchResult` struct or the array data itself.
    *   If `decodeIfPresent` returns `nil` but `container.contains` logs `true`, this indicates the JSON likely contains `"vector_results": null`, which should be handled correctly by `decodeIfPresent`, but confirms the key *is* recognized.
    *   If decoding succeeds and the count is > 0, the issue lies after decoding (move to Approach 2 or 4).

**Expected Outcome:**
This refined approach should definitively identify whether the `vector_results` key is visible to the decoder and, if so, pinpoint any errors occurring during the decoding of the array or its elements. If the key is consistently reported as *not* available despite being in the raw JSON, it suggests a deeper issue possibly outside the `Decodable` implementation itself (see Approach 5).

---

## Approach 2: End-to-End Data Tracing

**Goal:**
Follow the `vectorResults` data from the moment it's received by the client through its processing and state updates.

**Rationale:**
If decoding is successful (verified by Approach 1), the data might be getting lost or ignored during the subsequent steps where the decoded event is processed and used to update the application state (ViewModel, Message object).

### Steps

1.  **Confirm Decoding (Approach 1):**
    Ensure Approach 1 shows successful decoding of `vectorResults` for the `experience_vectors` phase.

2.  **Log After Decoding:**
    In the `do` block from Approach 1, after successfully decoding, log the relevant parts of the decoded event object, specifically focusing on the `vectorResults` for the `experience_vectors` phase.

    ```swift
    // Inside the successful 'do' block after decoding
    print("✅ Successfully decoded event for phase: \(event.phase)")
    if event.phase == "experience_vectors", let vectors = event.vectorResults {
        print("📊 DECODED DATA: Phase=\(event.phase), VectorCount=\(vectors.count)")
        // Log IDs for confirmation
        let vectorIDs = vectors.compactMap { $0.id }.joined(separator: ", ")
        print("   Vector IDs: [\(vectorIDs)]")
    }
    ```

3.  **Log Before State Update:**
    Trace the event object to where it's passed to your state management logic (e.g., `PostchainViewModel.updatePhaseData`). Before calling the update function, log the `vectorResults` count from the event object being passed.

    ```swift
    // Example: Just before calling viewModel.updatePhaseData
    print("➡️ Passing event to ViewModel: Phase=\(event.phase), VectorCount=\(event.vectorResults?.count ?? -1)")
    viewModel.updatePhaseData(...) // Pass the event
    ```

4.  **Log Inside State Update:**
    Go into the `updatePhaseData` function (or equivalent) in `PostchainViewModel.swift`. Log:
    *   The incoming parameters (phase, `vectorResults` count/IDs).
    *   The target `messageId`.
    *   The state of the relevant `Message` object *before* the update (especially its existing `vectorSearchResults`).
    *   The state of the `Message` object *after* the update.

    ```swift
    // Inside PostchainViewModel.updatePhaseData
    func updatePhaseData(..., vectorResults: [VectorSearchResult]? = nil, messageId: String? = nil) {
        let targetMessageId = messageId ?? self.activeMessageId
        print("🔄 VIEWMODEL UPDATE: Phase=\(phase), IncomingVectorCount=\(vectorResults?.count ?? -1), MsgID=\(targetMessageId)")

        if let msg = findMessage(by: targetMessageId) {
            print("   BEFORE Update: MsgID=\(msg.id), ExistingVectorCount=\(msg.vectorSearchResults.count)")

            // --- Your existing update logic here ---
            if let newVectorResults = vectorResults {
                 msg.vectorSearchResults = newVectorResults // Or append/merge logic? Check this!
                 print("   Applied \(newVectorResults.count) vectors")
            } else if phase != .experienceVectors { // Assuming Phase is an enum
                 print("   No vectors in this event, preserving existing ones.") // Ensure non-vector phases don't clear data
            }
            // ... update other properties ...
            // --- End of update logic ---

            print("   AFTER Update: MsgID=\(msg.id), FinalVectorCount=\(msg.vectorSearchResults.count)")
            // Ensure objectWillChange is called appropriately if needed
            // self.objectWillChange.send()
            // msg.objectWillChange.send()
        } else {
            print("   ERROR: Message not found for ID \(targetMessageId)")
        }
    }
    ```

5.  **Log in UI Interaction:**
    In the code that handles the click on a `#<number>` reference (likely in `PaginatedMarkdownView` or `PhaseCard`), log the reference number clicked and the state of `message.vectorSearchResults` at that exact moment.

    ```swift
    // Example: Inside the click handler for a vector reference
    func handleVectorReferenceClick(referenceNumber: Int, message: Message) {
        print("🖱️ Vector Reference Clicked: #\(referenceNumber)")
        print("   Message ID: \(message.id)")
        print("   Vector Results available at click time: \(message.vectorSearchResults.count)")
        if referenceNumber > 0 && referenceNumber <= message.vectorSearchResults.count {
            let vector = message.vectorSearchResults[referenceNumber - 1] // 0-based index
            print("   Vector Data: ID=\(vector.id ?? "nil"), Content=\(vector.content.prefix(30))...")
            // ... logic to display the vector
        } else {
            print("   ERROR: Reference number \(referenceNumber) is out of bounds for \(message.vectorSearchResults.count) available vectors.")
            // ... logic to show "Vector Reference Not Found" error
        }
    }
    ```

6.  **Run and Analyze:**
    Execute the app, trigger the workflow, and click a vector reference. Follow the logs:
    *   Does the `experience_vectors` event show decoded vectors?
    *   Are these vectors passed to `updatePhaseData`?
    *   Does `updatePhaseData` correctly assign them to the `Message` object?
    *   Does a later phase event (e.g., `understanding`, `yield`) cause the `Message` object's `vectorSearchResults` to be cleared or overwritten? (This is a common state management bug).
    *   When you click the reference, does the log show the expected number of vectors available for that message?

**Expected Outcome:**
This trace will reveal where the data flow breaks – whether the decoded data isn't passed correctly, if the state update logic is flawed (e.g., overwriting), or if the UI is accessing stale/incorrect state.

---

## Approach 3: Isolate the `experience_vectors` Event

**Goal:**
Simplify the scenario to determine if the client can handle just the `experience_vectors` event correctly, without interference from subsequent phase events.

**Rationale:**
Complex interactions and state updates from multiple, rapidly arriving SSE events can mask bugs. Isolating the problematic event type helps confirm if the fundamental handling for that specific event is correct.

### Steps

1.  **Modify Backend (Temporarily):**
    In `api/app/postchain/langchain_workflow.py`, find the `run_langchain_postchain_workflow` function. After the `yield` statement for the `experience_vectors` phase, add a `return` statement or simply stop yielding further events. Make it send only the `action` and `experience_vectors` events for a single request.

    ```python
    # Inside run_langchain_postchain_workflow in langchain_workflow.py
    # ... after yielding the experience_vectors event ...
    yield {
        "phase": "experience_vectors",
        "status": "complete",
        "content": exp_vectors_output.experience_vectors_response.content,
        # ... other fields ...
        "vector_results": vector_result_data
    }
    print("DEBUG: Stopping workflow after experience_vectors for isolation test.")
    return # Stop the async generator here
    # --- The rest of the phases will not run ---
    ```

2.  **Restart Backend:**
    Apply the change and restart the Python API server.

3.  **Run Client:**
    Start the iOS app and trigger the workflow.

4.  **Observe Client Behavior:**
    Use the logs and debugging techniques from Approach 1 and 2.
    *   Does the `experience_vectors` event arrive?
    *   Is it decoded successfully (check logs from Approach 1)?
    *   Does `updatePhaseData` get called with the vector data?
    *   Is the `vectorSearchResults` property on the corresponding `Message` object populated correctly?
    *   If you were to hypothetically click a reference now, would the data be available (check debugger or logs from Approach 2, Step 5)?

**Expected Outcome:**
If the client correctly processes the isolated `experience_vectors` event and populates the `Message` state, this strongly implies the problem occurs due to interactions with subsequent phase events (confirming the state overwrite hypothesis from Approach 2). If it still fails, the issue lies within the decoding or initial processing logic for that specific event type itself.

---

## Approach 4: Scrutinize State Update and Merging Logic

**Goal:**
Verify that the client-side state management logic correctly handles the arrival of multiple phase events for the same message, ensuring data (like `vectorResults`) isn't lost.

**Rationale:**
When multiple events update the same underlying `Message` object, the update logic must correctly merge or preserve data. A common bug is for an event without `vectorResults` (like `yield`) to overwrite or clear the `vectorResults` that were previously set by the `experience_vectors` event.

### Steps

1.  **Identify State Update Code:**
    Locate the function responsible for updating the `Message` object when a `PostchainStreamEvent` arrives (likely `PostchainViewModel.updatePhaseData` or potentially logic within the `Message` class itself if it receives events directly).

2.  **Review `vectorResults` Update:**
    Examine how the `message.vectorSearchResults` property (or equivalent) is updated.
    *   **Is it conditional?** Does it only update `vectorSearchResults` if the incoming `event.vectorResults` is non-nil and non-empty? This is generally the correct approach.
    *   **Is it overwriting?** Is there a line like `message.vectorSearchResults = event.vectorResults` (or `nil`) that executes even when `event.vectorResults` is empty or `nil` for phases other than `experience_vectors`? This would be incorrect and would clear the data.

3.  **Add Defensive Logging:**
    Add logs specifically around the `vectorResults` update logic.

    ```swift
    // Inside the state update function (e.g., PostchainViewModel.updatePhaseData)
    if let newVectorResults = event.vectorResults { // Assuming event is the decoded PostchainStreamEvent
        print("🧠 STATE UPDATE: Received \(newVectorResults.count) vector results for phase \(event.phase). Updating message.")
        // Ensure this assignment ONLY happens if newVectorResults is relevant for the current phase
        // Typically, only experience_vectors (and maybe understanding/yield if they also reference) should *set* this.
        if event.phase == "experience_vectors" || !newVectorResults.isEmpty { // Be careful with this condition
            message.vectorSearchResults = newVectorResults
        } else {
             print("🧠 STATE UPDATE: Phase \(event.phase) has nil/empty vectors. *Not* updating message vectors.")
        }
    } else {
        // IMPORTANT: If the event has nil vectorResults, DO NOT clear existing data on the message
        print("🧠 STATE UPDATE: Event for phase \(event.phase) has nil vectorResults. *Preserving* existing message vectors (\(message.vectorSearchResults.count)).")
        // DO NOT DO THIS: message.vectorSearchResults = nil // <-- This would be a bug!
    }
    ```

4.  **Use Debugger:**
    Set breakpoints within the state update logic. Step through the execution flow as different phase events arrive for the same message. Observe:
    *   When does the `experience_vectors` event arrive and populate `message.vectorSearchResults`?
    *   When do subsequent events (e.g., `understanding`, `yield`) arrive?
    *   Does the logic correctly *skip* overwriting `message.vectorSearchResults` when these later events arrive without vector data?
**Expected Outcome:**
This approach will pinpoint flaws in the state update logic, specifically identifying if non-`experience_vectors` phases are incorrectly clearing the `vectorSearchResults` data. It helps ensure data persistence across multiple event updates for a single message.

---

## Approach 5: Manual JSON Parsing (Fallback)

**Goal:**
Bypass `Codable` for the problematic `vector_results` field if standard decoding continues to fail inexplicably.

**Rationale:**
If `Codable`'s `KeyedDecodingContainer` consistently fails to recognize or decode the `vector_results` key despite it being present in the raw JSON and `CodingKeys` being correct, manually parsing that specific part of the JSON using `JSONSerialization` can serve as a workaround and confirm data presence.

### Steps

1.  **Modify Decoder `init`:**
    Inside the `init(from decoder: Decoder)` for `PostchainEvent` / `PostchainStreamEvent`, *before* the standard `Codable` decoding attempts for `vectorResults`, try to manually extract it.

    ```swift
    // Inside PostchainEvent/PostchainStreamEvent init(from decoder: Decoder)

    // ... decode other properties ...

    // --- Manual JSON Parsing Fallback ---
    var manuallyParsedVectors: [VectorSearchResult]? = nil
    do {
        // 1. Get the raw data used by the decoder
        // Ensure you pass this data via userInfo when calling decode()
        guard let data = decoder.userInfo[CodingUserInfoKey(rawValue: "rawData")!] as? Data else {
             print("⚠️ MANUAL PARSE: Could not get raw data from decoder userInfo")
             throw APIError.decodingError(context: "Missing rawData in userInfo for manual parse") // Or handle differently
        }

        // 2. Use JSONSerialization to get a dictionary
        if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            // 3. Check if the key exists
            if let resultsArray = jsonObject["vector_results"] as? [[String: Any]] {
                 print("🔵 MANUAL PARSE: Found 'vector_results' key with \(resultsArray.count) items.")
                 // 4. Attempt to decode each item individually
                 var tempVectors: [VectorSearchResult] = []
                 let itemDecoder = JSONDecoder() // Use a fresh decoder for items
                 for itemDict in resultsArray {
                     do {
                         let itemData = try JSONSerialization.data(withJSONObject: itemDict, options: [])
                         let vector = try itemDecoder.decode(VectorSearchResult.self, from: itemData)
                         tempVectors.append(vector)
                     } catch {
                         print("🔵 MANUAL PARSE: Failed to decode individual vector item: \(error). Item: \(itemDict)")
                         // Decide whether to skip the item or fail entirely
                     }
                 }
                 manuallyParsedVectors = tempVectors
                 print("🔵 MANUAL PARSE: Successfully parsed \(manuallyParsedVectors?.count ?? 0) vectors.")
            } else {
                 print("🔵 MANUAL PARSE: 'vector_results' key not found or not an array in JSONSerialization object.")
            }
        } else {
             print("🔵 MANUAL PARSE: Could not cast JSON root to [String: Any].")
        }
    } catch {
        print("🔵 MANUAL PARSE: Error during manual JSONSerialization: \(error)")
    }
    // --- End Manual Fallback ---

    // Assign the manually parsed results if available, otherwise proceed with Codable attempt
    self.vectorResults = manuallyParsedVectors
    if self.vectorResults != nil {
         print("🔵 MANUAL PARSE: Assigned manually parsed vectors.")
    } else {
         // Proceed with the standard Codable attempt (from Approach 1, Step 3)
         // This block will now only run if manual parsing failed or found nothing.
         print("🔵 MANUAL PARSE: Manual parsing failed or found no vectors, falling back to standard Codable decoding.")
         do {
             vectorResults = try container.decodeIfPresent([VectorSearchResult].self, forKey: .vectorResults)
             // ... rest of Codable decoding logic from Approach 1 ...
             if vectorResults != nil {
                 print("🔴 VECTOR: Standard Codable decoding succeeded after manual parse failed.")
             } else {
                 print("🔴 VECTOR: Standard Codable decoding also failed after manual parse.")
             }
         } catch {
            // ... Codable error handling from Approach 1 ...
            print("🔴 VECTOR: Standard Codable decoding failed with error: \(error)")
            vectorResults = nil
         }
    }


    // ... rest of init ...

    ```

2.  **Pass Raw Data via `userInfo`:**
    When you call `JSONDecoder().decode(...)` in `PostchainAPIClient.swift` (or wherever decoding happens), you *must* pass the original `Data` object via the decoder's `userInfo` dictionary.

    ```swift
    // Inside your SSE event handler (e.g., in PostchainAPIClient.swift)
    // ... after getting jsonData ...
    do {
        let decoder = JSONDecoder()
        // Pass the raw data for manual parsing fallback
        // Use a unique key to avoid potential conflicts
        let rawDataUserInfoKey = CodingUserInfoKey(rawValue: "rawData")!
        decoder.userInfo[rawDataUserInfoKey] = jsonData

        let event = try decoder.decode(PostchainStreamEvent.self, from: jsonData) // Or PostchainEvent
        print("✅ Successfully decoded event for phase: \(event.phase)")
        // ... rest of processing ...
    } catch {
        // ... error handling ...
    }
    ```

3.  **Run and Analyze:**
    Execute the app and check the `🔵 MANUAL PARSE:` logs.
    *   If manual parsing succeeds (`Assigned manually parsed vectors`), it confirms the data is present and correctly structured in the JSON, but `Codable` is failing for an unknown reason. You could potentially rely on the manually parsed data.
    *   If manual parsing also fails to find the key or decode items, it might indicate a more fundamental issue with the JSON data itself or the `VectorSearchResult` struct's `Decodable` conformance. Check the specific errors logged during manual parsing.
    *   If manual parsing fails but the subsequent standard `Codable` attempt *succeeds* (unlikely given previous results, but possible), it might indicate an intermittent issue or a problem with how the `userInfo` data was accessed.

**Expected Outcome:**
This approach provides a robust fallback if `Codable` proves unreliable for the `vector_results` field. It helps isolate whether the problem is with the `Codable` infrastructure itself or the underlying data structure by attempting a completely different parsing method for the problematic section.
This approach will pinpoint flaws in the state update logic, specifically identifying if non-`experience_vectors` phases are incorrectly clearing the `vectorSearchResults` data. It helps ensure data persistence across multiple event updates for a single message.
