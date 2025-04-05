import XCTest
@testable import Choir

final class RESTPostchainAPIClientTests: XCTestCase {
    
//    func testLangchainRequestBodyEncoding() throws {
//        // Create a request body
//        let requestBody = LangchainRequestBody(
//            userQuery: "Test query",
//            threadId: "test-thread-id"
//        )
//        
//        // Create a JSON encoder
//        let encoder = JSONEncoder()
//        encoder.keyEncodingStrategy = .convertToSnakeCase
//        
//        // Encode the request body
//        let data = try encoder.encode(requestBody)
//        
//        // Convert to JSON string for inspection
//        let jsonString = String(data: data, encoding: .utf8)!
//        
//        // Verify the JSON structure
//        XCTAssertTrue(jsonString.contains("\"user_query\":\"Test query\""))
//        XCTAssertTrue(jsonString.contains("\"thread_id\":\"test-thread-id\""))
//    }
//    
//    func testPostchainLangchainEventDecoding() throws {
//        // Create a JSON string representing a langchain event
//        let jsonString = """
//        {
//            "phase": "action",
//            "status": "complete",
//            "content": "This is a test response",
//            "web_results": [
//                {
//                    "title": "Test Result",
//                    "url": "https://example.com",
//                    "content": "Test content",
//                    "provider": "brave_search"
//                }
//            ],
//            "vector_results": [
//                {
//                    "content": "Vector result content",
//                    "score": 0.95,
//                    "metadata": {
//                        "source": "test"
//                    },
//                    "provider": "qdrant_search"
//                }
//            ]
//        }
//        """
//        
//        // Create a JSON decoder
//        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//        
//        // Decode the JSON string
//        let data = jsonString.data(using: .utf8)!
//        let event = try decoder.decode(PostchainLangchainEvent.self, from: data)
//        
//        // Verify the decoded event
//        XCTAssertEqual(event.phase, "action")
//        XCTAssertEqual(event.status, "complete")
//        XCTAssertEqual(event.content, "This is a test response")
//        XCTAssertEqual(event.webResults?.count, 1)
//        XCTAssertEqual(event.webResults?.first?.title, "Test Result")
//        XCTAssertEqual(event.vectorResults?.count, 1)
//        XCTAssertEqual(event.vectorResults?.first?.content, "Vector result content")
//        XCTAssertEqual(event.vectorResults?.first?.score, 0.95)
//    }
//    
//    func testThreadRecoveryResponseDecoding() throws {
//        // Create a JSON string representing a thread recovery response
//        let jsonString = """
//        {
//            "status": "recovered",
//            "thread_id": "test-thread-id",
//            "phase_states": {
//                "action": "complete",
//                "experience": "complete",
//                "intention": "processing"
//            },
//            "current_phase": "intention",
//            "message_count": 5
//        }
//        """
//        
//        // Create a JSON decoder
//        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//        
//        // Decode the JSON string
//        let data = jsonString.data(using: .utf8)!
//        let response = try decoder.decode(ThreadRecoveryResponse.self, from: data)
//        
//        // Verify the decoded response
//        XCTAssertEqual(response.status, "recovered")
//        XCTAssertEqual(response.threadId, "test-thread-id")
//        XCTAssertEqual(response.currentPhase, "intention")
//        XCTAssertEqual(response.messageCount, 5)
//        XCTAssertEqual(response.phaseStates?["action"], "complete")
//        XCTAssertEqual(response.phaseStates?["experience"], "complete")
//        XCTAssertEqual(response.phaseStates?["intention"], "processing")
//    }
}
