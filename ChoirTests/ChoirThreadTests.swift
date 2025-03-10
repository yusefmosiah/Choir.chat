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

    func testPhaseSupport() {
        let phaseData: [Phase: String] = [
            .action: "Action phase content",
            .experience: "Experience phase content"
        ]
        
        let message = Message(
            content: "Test message", 
            isUser: false,
            phases: phaseData
        )
        
        XCTAssertEqual(message.phases[.action], "Action phase content")
        XCTAssertEqual(message.phases[.experience], "Experience phase content")
        
        // Test empty phases are returned for undefined phases
        XCTAssertEqual(message.phases[.intention], "")
    }
    
    func testCoordinatorBasics() async throws {
        let coordinator = TestPostchainCoordinator()
        let thread = ChoirThread()

        // Set current thread
        coordinator.currentChoirThread = thread

        // Process a message
        try await coordinator.process("Test input")

        // Verify response was received
        XCTAssertEqual(coordinator.responses[.action], "Here's a response to: Test input")
    }
}