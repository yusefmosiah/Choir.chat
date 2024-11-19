import XCTest
@testable import Choir

final class ChorusAPIClientTests: XCTestCase {
    let api = ChorusAPIClient()

    func testActionEndpoint() async throws {
        let response: APIResponse<ActionResponse> = try await api.post(
            endpoint: "action",
            body: ["content": "What is the capital of France?"]
        )

        print("Response Success?: \(response.success)")
        print("Response Data: \(String(describing: response.data))")

        if response.data == nil {
            XCTFail("Response data was nil. Full response: \(response)")
        }

        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.data)

        let data = response.data!
        XCTAssertEqual(data.step, "Action")
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

    func testErrorHandling() async throws {
        // Test invalid URL
        let invalidAPI = ChorusAPIClient()
        invalidAPI.baseURL = ""

        do {
            let _: APIResponse<ActionResponse> = try await invalidAPI.post(
                endpoint: "action",
                body: ["content": "This should fail"]
            )
            XCTFail("Expected invalid URL error")
        } catch APIError.invalidURL {
            // Success
        } catch {
            XCTFail("Got unexpected error: \(error)")
        }

        // Test server error
        do {
            let _: APIResponse<ActionResponse> = try await api.post(
                endpoint: "nonexistent",
                body: ["content": "This should fail"]
            )
            XCTFail("Expected server error")
        } catch APIError.serverError {
            // Success
        } catch {
            XCTFail("Got unexpected error: \(error)")
        }
    }

    func testCancellation() async throws {
        let task = Task {
            let _: APIResponse<ActionResponse> = try await api.post(
                endpoint: "action",
                body: ["content": "This should be cancelled"]
            )
        }

        // Cancel immediately
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation error")
        } catch APIError.cancelled {
            // Success
        } catch {
            XCTFail("Got unexpected error: \(error)")
        }
    }
}
