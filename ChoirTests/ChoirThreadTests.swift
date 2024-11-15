import XCTest
@testable import Choir

@MainActor
final class ChoirThreadTests: XCTestCase {
    func testChoirThreadCreation() {
        let thread = ChoirThread()
        XCTAssertNotNil(thread.id)
        XCTAssertFalse(thread.title.isEmpty)
        XCTAssertTrue(thread.messages.isEmpty)
    }

    func testMessageManagement() {
        let thread = ChoirThread()

        // Create and add a message
        let message = Message(
            content: "Test message",
            isUser: true
        )
        thread.messages.append(message)

        XCTAssertEqual(thread.messages.count, 1)
        XCTAssertEqual(thread.messages[0].content, "Test message")
    }

    func testContextInCoordinator() async throws {
        let coordinator = RESTChorusCoordinator()
        let thread = ChoirThread()

        // Add a message directly to messages array
        let message = Message(
            content: "Hello",
            isUser: true
        )
        thread.messages.append(message)

        // Set current thread
        coordinator.currentChoirThread = thread

        // Process with context
        try await coordinator.process("How are you?")

        // Verify response was received
        XCTAssertNotNil(coordinator.actionResponse)
    }

    func testPasswordMemory() async throws {
        let coordinator = RESTChorusCoordinator()
        let thread = ChoirThread()

        // First message
        let firstMessage = Message(
            content: "password = 421",
            isUser: true
        )
        thread.messages.append(firstMessage)

        // Set thread and process
        coordinator.currentChoirThread = thread
        try await coordinator.process("password = 421")

        // Add AI response if received
        if let response = coordinator.yieldResponse?.content {
            let aiMessage = Message(
                content: response,
                isUser: false
            )
            thread.messages.append(aiMessage)
        }

        // Process follow-up question
        try await coordinator.process("what's the password?")

        // Verify response contains password
        guard let finalResponse = coordinator.yieldResponse?.content else {
            XCTFail("No yield response received")
            return
        }

        XCTAssertTrue(
            finalResponse.contains("421"),
            "Response should include the password: \(finalResponse)"
        )
    }
}
