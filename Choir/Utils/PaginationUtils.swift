import SwiftUI
import UIKit

struct PhaseContentSelection {
    let fullContent: String
    let currentPageRange: NSRange
}

class TextSelectionManager: ObservableObject {
    static let shared = TextSelectionManager()

    @Published var showingSheet = false
    @Published var selectedText = ""
    @Published var activeText: String? = nil
    @Published var isShowingMenu = false
    @Published var isInteractionDisabled = false
    @Published var preventBackgroundUpdates = false
    @Published var phaseContentSelection: PhaseContentSelection? = nil

    // Citation information
    @Published var citationExplanation: String? = nil
    @Published var citationReward: [String: Any]? = nil

    // Track the current vector ID being fetched to prevent duplicate API calls
    private var currentVectorId: String? = nil
    private var isProcessingVectorRequest = false

    func showSheet(withText text: String) {
        self.selectedText = text
        self.phaseContentSelection = nil
        self.showingSheet = true
        self.preventBackgroundUpdates = true
    }

    // Show sheet for vector content with duplicate prevention
    func showVectorSheet(withText text: String, vectorId: String) {
        // If we're already processing this vector ID, just update the text
        if isProcessingVectorRequest && currentVectorId == vectorId {
            // Add a small delay to ensure the sheet is fully presented
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.selectedText = text
            }
            return
        }

        // If we're already showing a sheet for a different vector, dismiss it first
        if isProcessingVectorRequest && currentVectorId != vectorId && showingSheet {
            // Dismiss the current sheet
            self.showingSheet = false

            // Wait a moment for the dismissal animation, then show the new sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }

                // Set the current vector ID and mark as processing
                self.currentVectorId = vectorId
                self.isProcessingVectorRequest = true

                // Show the sheet
                self.selectedText = text
                self.phaseContentSelection = nil
                self.showingSheet = true
                self.preventBackgroundUpdates = true
            }
            return
        }

        // Set the current vector ID and mark as processing
        currentVectorId = vectorId
        isProcessingVectorRequest = true

        // Show the sheet
        self.selectedText = text
        self.phaseContentSelection = nil
        self.showingSheet = true
        self.preventBackgroundUpdates = true
    }

    // Update the content of an already displayed vector sheet
    func updateVectorSheet(withText text: String, vectorId: String) {
        // Only update if we're already showing this vector
        if isProcessingVectorRequest && currentVectorId == vectorId && showingSheet {
            // Add a small delay to ensure the sheet is fully presented
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.selectedText = text
            }
        }
    }

    func showSheet(withPhaseContent content: String, currentPageRange: NSRange) {
        self.phaseContentSelection = PhaseContentSelection(
            fullContent: content,
            currentPageRange: currentPageRange
        )
        self.showingSheet = true
        self.preventBackgroundUpdates = true
    }

    func setActiveText(_ text: String) {
        self.activeText = text
        self.isShowingMenu = true
    }

    func clearActiveText() {
        self.activeText = nil
        self.isShowingMenu = false
    }

    func sheetDismissed() {
        self.showingSheet = false
        self.preventBackgroundUpdates = false

        // Reset vector request tracking
        self.currentVectorId = nil
        self.isProcessingVectorRequest = false

        // Reset citation information
        self.citationExplanation = nil
        self.citationReward = nil
    }

    // Show sheet with citation information
    func showVectorSheetWithCitation(withText text: String, vectorId: String, explanation: String?, reward: [String: Any]?) {
        // Set citation information
        self.citationExplanation = explanation
        self.citationReward = reward

        // Show the vector sheet
        showVectorSheet(withText: text, vectorId: vectorId)
    }

    func temporarilyDisableInteractions() {
        if preventBackgroundUpdates { return }
        isInteractionDisabled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isInteractionDisabled = false
        }
    }
}

// TextMeasurer class has been removed as it's no longer needed.
// The MarkdownPaginator class now handles all pagination logic with improved
// clean break detection and accessibility support.
