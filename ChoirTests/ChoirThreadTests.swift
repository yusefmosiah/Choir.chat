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
        let coordinator = RESTPostchainCoordinator()
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

    func testMultiturnChat() async throws {
        let coordinator = RESTPostchainCoordinator()
        let thread = ChoirThread()

        // First message
        let firstMessage = Message(
            content: "remember the number 421. this is a test of multiturn chat. in the next message, you will be asked for the special number.",
            isUser: true
        )
        thread.messages.append(firstMessage)

        // Set thread and process
        coordinator.currentChoirThread = thread
        try await coordinator.process(firstMessage.content)

        // Add AI response if received
        if let response = coordinator.yieldResponse?.content {
            let aiMessage = Message(
                content: response,
                isUser: false,
                chorusResult: MessageChorusResult(phases: coordinator.responses)
            )
            thread.messages.append(aiMessage)
        }

        // Second message - don't drop context
        let followUpMessage = Message(
            content: "what's the special number?",
            isUser: true
        )
        thread.messages.append(followUpMessage)

        // Process follow-up with full context
        try await coordinator.process(followUpMessage.content)

        // Verify response contains number
        guard let finalResponse = coordinator.yieldResponse?.content else {
            XCTFail("No yield response received")
            return
        }

        XCTAssertTrue(
            finalResponse.contains("421"),
            "Response should include the special number: \(finalResponse)"
        )
    }
}
