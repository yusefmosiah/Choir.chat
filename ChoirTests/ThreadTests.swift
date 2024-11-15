import XCTest
@testable import Choir

final class ThreadTests: XCTestCase {
    func testContextManagement() {
        let thread = Thread()

        // Test adding messages until we exceed token limit
        let longMessage = String(repeating: "This is a long message. ", count: 50000) // ~1M chars = ~250k tokens
        thread.addMessage(longMessage)

        // Add some smaller messages
        for i in 0..<10 {
            thread.addMessage("Message \(i)")
        }

        // Verify long message was removed due to token limit
        XCTAssertFalse(thread.getContext().contains(where: { $0.content == longMessage }))

        // Verify recent smaller messages are retained
        XCTAssertEqual(thread.getContext().last?.content, "Message 9")
    }

    func testTokenEstimation() {
        let thread = Thread()

        // Test various message sizes
        let messages = [
            String(repeating: "a", count: 4),     // ~1 token
            String(repeating: "word ", count: 50), // ~50 tokens
            String(repeating: "This is a test message. ", count: 1000) // ~5000 tokens
        ]

        for message in messages {
            thread.addMessage(message)
        }

        // Verify all messages fit within token limit
        XCTAssertTrue(thread.getContext().count == messages.count)
    }

    func testContextInCoordinator() async throws {
        let coordinator = RESTChorusCoordinator()
        let thread = Thread()

        // Add some context
        thread.addMessage("Hello")
        thread.addMessage("Hi there", isUser: false)

        // Process with context
        try await coordinator.process("How are you?", thread: thread)

        // Verify context was used
        XCTAssertNotNil(coordinator.experienceResponse?.priors)
    }

    func testActionPhaseContext() async throws {
        let coordinator = RESTChorusCoordinator()
        let thread = Thread()

        // Add some context messages
        thread.addMessage("First message")
        thread.addMessage("Hello there", isUser: false)
        thread.addMessage("Second message")

        // Set as current thread
        coordinator.currentThread = thread

        // Process new message
        try await coordinator.process("What were the previous messages?")

        // Verify response acknowledges context
        XCTAssertNotNil(coordinator.actionResponse)
        let response = coordinator.actionResponse?.content ?? ""
        XCTAssertTrue(
            response.contains("First message") ||
            response.contains("previous messages") ||
            response.contains("conversation history"),
            "Response should acknowledge context: \(response)"
        )
    }
}
