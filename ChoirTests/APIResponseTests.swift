import XCTest
@testable import Choir

final class APIResponseTests: XCTestCase {
    func testActionResponseDecoding() throws {
        let json = """
        {
            "success": true,
            "data": {
                "step": "action",
                "content": "Paris",
                "confidence": 0.95,
                "reasoning": "Paris is the capital of France"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIResponse<ActionResponse>.self, from: data)

        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.data)
        let responseData = response.data!
        XCTAssertEqual(responseData.step, "action")
        XCTAssertEqual(responseData.content, "Paris")
        XCTAssertEqual(responseData.confidence, 0.95)
        XCTAssertEqual(responseData.reasoning, "Paris is the capital of France")
    }
}
