import XCTest
@testable import Choir

final class ChorusAPIClientTests: XCTestCase {
    let api = ChorusAPIClient()

    func testActionEndpoint() async throws {
        let response: APIResponse<ActionResponse> = try await api.post(
            endpoint: "action",
            body: ["content": "What is the capital of France?"]
        )

        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.data)

        let data = response.data!
        XCTAssertEqual(data.step, "action")
        XCTAssertFalse(data.content.isEmpty)
        XCTAssertGreaterThan(data.confidence, 0)
        XCTAssertNotNil(data.reasoning)
    }

    func testTimeout() async throws {
        let shortTimeoutAPI = ChorusAPIClient(timeout: 0.001)

        do {
            let _: APIResponse<ActionResponse> = try await shortTimeoutAPI.post(
                endpoint: "action",
                body: ["content": "This should timeout"]
            )
            XCTFail("Expected timeout error")
        } catch APIError.timeout {
            // Success
        } catch {
            XCTFail("Got unexpected error: \(error)")
        }
    }
}
