import XCTest
@testable import Choir

final class ChorusAPIClientTests: XCTestCase {
    let api = ChorusAPIClient()

    // Test data
    let testContent = "What is the capital of France?"
    let testThreadId: String? = nil
    let testContext: [MessageContext]? = nil

    func testActionEndpoint() async throws {
        let actionBody = ActionRequestBody(
            content: testContent,
            threadID: testThreadId,
            context: testContext
        )

        let response: ActionResponse = try await api.post(endpoint: "action", body: actionBody)
        print("Action Response: \(String(describing: response))")

        XCTAssertEqual(response.step.lowercased(), "action")
        XCTAssertFalse(response.content.isEmpty)
        XCTAssertGreaterThan(response.confidence, 0)
        XCTAssertNotNil(response.reasoning)
    }

    func testExperienceEndpoint() async throws {
        let experienceBody = ExperienceRequestBody(
            content: testContent,
            actionResponse: "Test action response",
            threadID: testThreadId,
            context: testContext
        )

        let response: ExperienceResponse = try await api.post(endpoint: "experience", body: experienceBody)
        print("Experience Response: \(String(describing: response))")

        XCTAssertEqual(response.step.lowercased(), "experience")
        XCTAssertFalse(response.content.isEmpty)
        XCTAssertGreaterThan(response.confidence, 0)
        XCTAssertNotNil(response.reasoning)
        XCTAssertNotNil(response.priors)
    }

    func testIntentionEndpoint() async throws {
        let intentionBody = IntentionRequestBody(
            content: testContent,
            actionResponse: "Test action response",
            experienceResponse: "Test experience response",
            priors: [:],
            threadID: testThreadId,
            context: testContext
        )

        let response: IntentionResponse = try await api.post(endpoint: "intention", body: intentionBody)
        print("Intention Response: \(String(describing: response))")

        XCTAssertEqual(response.step.lowercased(), "intention")
        XCTAssertFalse(response.content.isEmpty)
        XCTAssertGreaterThan(response.confidence, 0)
        XCTAssertNotNil(response.reasoning)
        // todo
//        XCTAssertNotNil(response.selectedPriors)
    }

    func testObservationEndpoint() async throws {
        let observationBody = ObservationRequestBody(
            content: testContent,
            actionResponse: "Test action response",
            experienceResponse: "Test experience response",
            intentionResponse: "Test intention response",
            selectedPriors: [],
            priors: [:],
            threadID: testThreadId,
            context: testContext
        )

        let response: ObservationResponse = try await api.post(endpoint: "observation", body: observationBody)
        print("Observation Response: \(String(describing: response))")

        XCTAssertEqual(response.step.lowercased(), "observation")
        XCTAssertFalse(response.content.isEmpty)
        XCTAssertGreaterThan(response.confidence, 0)
        XCTAssertNotNil(response.reasoning)
    }

    func testUnderstandingEndpoint() async throws {
        let understandingBody = UnderstandingRequestBody(
            content: testContent,
            actionResponse: "Test action response",
            experienceResponse: "Test experience response",
            intentionResponse: "Test intention response",
            observationResponse: "Test observation response",
            patterns: [],
            selectedPriors: [],
            threadID: testThreadId,
            context: testContext
        )

        let response: UnderstandingResponse = try await api.post(endpoint: "understanding", body: understandingBody)
        print("Understanding Response: \(String(describing: response))")

        XCTAssertEqual(response.step.lowercased(), "understanding")
        XCTAssertFalse(response.content.isEmpty)
        XCTAssertGreaterThan(response.confidence, 0)
        XCTAssertNotNil(response.reasoning)
        // todo
//        XCTAssertNotNil(response.shouldYield)
    }

    func testYieldEndpoint() async throws {
        let yieldBody = YieldRequestBody(
            content: testContent,
            actionResponse: "Test action response",
            experienceResponse: "Test experience response",
            intentionResponse: "Test intention response",
            observationResponse: "Test observation response",
            understandingResponse: "Test understanding response",
            selectedPriors: [],
            priors: [:],
            threadID: testThreadId,
            context: testContext
        )

        let response: YieldResponse = try await api.post(endpoint: "yield", body: yieldBody)
        print("Yield Response: \(String(describing: response))")

        XCTAssertEqual(response.step.lowercased(), "yield")
        XCTAssertFalse(response.content.isEmpty)
        XCTAssertGreaterThan(response.confidence, 0)
        XCTAssertNotNil(response.reasoning)
    }

    func testTimeout() async throws {
        let shortTimeoutAPI = ChorusAPIClient(timeout: 0.001)

        do {
            let actionBody = ActionRequestBody(
                content: "This should timeout",
                threadID: nil,
                context: nil
            )

            let _: ActionResponse = try await shortTimeoutAPI.post(
                endpoint: "action",
                body: actionBody
            )
            XCTFail("Expected timeout error")
        } catch APIError.timeout {
            // Success - expected timeout
        } catch {
            XCTFail("Got unexpected error: \(error)")
        }
    }
}
