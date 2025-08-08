//import XCTest
//import SwiftUI
//@testable import Choir
//
//class TurnContainerViewTests: XCTestCase {
//    
//    func testPageCreationDuringStreaming() {
//        // Create a mock coordinator and view model
//        let coordinator = PostchainCoordinatorImpl()
//        let viewModel = PostchainViewModel(coordinator: coordinator)
//        
//        // Create test messages
//        let userMessage = Message(content: "Test user message", isUser: true)
//        let aiMessage = Message(content: "", isUser: false, isStreaming: true)
//        
//        // Create the turn container view
//        let turnContainer = TurnContainerView(
//            userMessage: userMessage,
//            aiMessage: aiMessage,
//            viewModel: viewModel
//        )
//        
//        // Test that during streaming, all pages should be created
//        // even if phases don't have content yet
//        
//        // Simulate streaming state
//        aiMessage.isStreaming = true
//        
//        // The view should create pages for all phases during streaming
//        // This is tested indirectly by checking the page creation logic
//        
//        XCTAssertTrue(aiMessage.isStreaming, "AI message should be in streaming state")
//        
//        // Test that the streaming detection works with processingPhases
//        viewModel.processingPhases.insert(.action)
//        XCTAssertTrue(viewModel.processingPhases.contains(.action), "Processing phases should contain action")
//        
//        viewModel.processingPhases.insert(.yield)
//        XCTAssertTrue(viewModel.processingPhases.contains(.yield), "Processing phases should contain yield")
//        
//        // Test that phases are removed when complete
//        viewModel.processingPhases.remove(.action)
//        XCTAssertFalse(viewModel.processingPhases.contains(.action), "Processing phases should not contain action after removal")
//    }
//    
//    func testProcessingPhasesManagement() {
//        let coordinator = PostchainCoordinatorImpl()
//        let viewModel = PostchainViewModel(coordinator: coordinator)
//        
//        // Test that processing phases are properly managed
//        XCTAssertTrue(viewModel.processingPhases.isEmpty, "Processing phases should start empty")
//        
//        // Simulate coordinator updating processing phases
//        coordinator.processingPhases.insert(.action)
//        coordinator.processingPhases.insert(.experienceVectors)
//        
//        // Update view model state
//        viewModel.updateState()
//        
//        XCTAssertTrue(viewModel.processingPhases.contains(.action), "View model should reflect coordinator's processing phases")
//        XCTAssertTrue(viewModel.processingPhases.contains(.experienceVectors), "View model should reflect coordinator's processing phases")
//        
//        // Test removal
//        coordinator.processingPhases.remove(.action)
//        viewModel.updateState()
//        
//        XCTAssertFalse(viewModel.processingPhases.contains(.action), "View model should reflect phase removal")
//        XCTAssertTrue(viewModel.processingPhases.contains(.experienceVectors), "Other phases should remain")
//    }
//}
