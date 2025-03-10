import XCTest
@testable import Choir

final class APIResponseTests: XCTestCase {
    func testPostchainStreamEventDecoding() throws {
        let json = """
        {
            "current_phase": "action",
            "phase_state": "in_progress",
            "content": "Paris is the capital of France",
            "thread_id": "123e4567-e89b-12d3-a456-426614174000"
        }
        """

        let data = json.data(using: .utf8)!
        let event = try JSONDecoder().decode(PostchainStreamEvent.self, from: data)

        XCTAssertEqual(event.currentPhase, "action")
        XCTAssertEqual(event.phaseState, "in_progress")
        XCTAssertEqual(event.content, "Paris is the capital of France")
        XCTAssertEqual(event.threadID, "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertNil(event.error)
        XCTAssertNil(event.metadata)
    }
    
    func testSimplePostchainRequestBody() throws {
        let requestBody = SimplePostchainRequestBody(
            userQuery: "What is the capital of France?",
            threadID: "123e4567-e89b-12d3-a456-426614174000"
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(requestBody)
        let jsonString = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("user_query"))
        XCTAssertTrue(jsonString.contains("thread_id"))
        XCTAssertTrue(jsonString.contains("What is the capital of France?"))
        XCTAssertTrue(jsonString.contains("123e4567-e89b-12d3-a456-426614174000"))
    }
}