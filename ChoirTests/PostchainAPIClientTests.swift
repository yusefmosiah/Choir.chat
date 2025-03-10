import XCTest
@testable import Choir

final class PostchainAPIClientTests: XCTestCase {
    // Simple test to make sure the build succeeds - real tests would need to be rewritten
    // for the new streamlined API
    func testBasicStructures() {
        // Create postchain API client
        let apiClient = PostchainAPIClient()
        
        // Create a request body
        let requestBody = SimplePostchainRequestBody(
            userQuery: "Test query",
            threadID: UUID().uuidString
        )
        
        // Create a stream event
        let event = PostchainStreamEvent(
            currentPhase: "action",
            phaseState: "in_progress",
            content: "Test content",
            metadata: nil,
            threadID: UUID().uuidString,
            error: nil
        )
        
        // Verify these can be created successfully
        XCTAssertNotNil(apiClient)
        XCTAssertEqual(requestBody.userQuery, "Test query")
        XCTAssertEqual(event.currentPhase, "action")
        XCTAssertEqual(event.content, "Test content")
    }
}