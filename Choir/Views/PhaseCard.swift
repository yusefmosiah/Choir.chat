import SwiftUI
import Foundation

struct PhaseCard: View {
    let phase: Phase
    @ObservedObject var message: Message
    let isSelected: Bool
    var isLoading: Bool = false
    var priors: [Prior]? = nil
    @ObservedObject var viewModel: PostchainViewModel
    var messageId: String? // Message ID parameter
    
    // --- Computed Properties for Styling ---
    
    private var cardBackgroundColor: Color {
        phase == .yield ? Color.accentColor : Color(.systemBackground) // Use semantic color
    }
    
    private var primaryTextColor: Color {
        phase == .yield ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        phase == .yield ? .white.opacity(0.8) : .secondary
    }
    
    private var headerIconColor: Color {
        phase == .yield ? .white : .accentColor
    }
    
    private var shadowOpacity: Double {
        isSelected ? 0.2 : 0.1
    }
    
    private var shadowRadius: CGFloat {
        isSelected ? 8 : 3
    }
    
    private var shadowYOffset: CGFloat {
        isSelected ? 3 : 1
    }
    
    private var overlayStrokeColor: Color {
        if isSelected {
            return phase == .yield ? Color.white : Color.accentColor
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var overlayLineWidth: CGFloat {
        isSelected ? 2 : 1
    }
    
    // Binding for current page in the phase
    private var pageBinding: Binding<Int> {
        Binding<Int>(
            get: { message.currentPage(for: phase) },
            set: { message.setCurrentPage(for: phase, page: $0) }
        )
    }
    
    // --- Body ---
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: phase.symbol)
                    .imageScale(.medium)
                    .foregroundColor(headerIconColor)
                
                Text(phase.rawValue.capitalized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(secondaryTextColor) // Ensure progress view matches text color
                }
            }
            .padding(.bottom, 4)
            
            // Content Area
            let content = message.getPhaseContent(phase)
            if !content.isEmpty {
                GeometryReader { geometry in
                    if phase == .experience {
                        // Pass viewModel and messageId to ensure each experience phase has independent state
                        ExperienceSourcesView(viewModel: viewModel, messageId: messageId)
                    } else {
                        PaginatedTextView(
                            text: content,
                            availableSize: geometry.size,
                            currentPage: pageBinding
                        )
                    }
                }
            } else if isLoading {
                // Loading State
                VStack(spacing: 12) {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(secondaryTextColor) // Match text color
                        Text("Loading...")
                            .foregroundColor(secondaryTextColor)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                // Empty State
                Text("No content available")
                    .foregroundColor(.secondary) // Use standard secondary for empty state
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(shadowOpacity),
                        radius: shadowRadius,
                        x: 0,
                        y: shadowYOffset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(overlayStrokeColor, lineWidth: overlayLineWidth)
        )
        .padding(.horizontal, 4)
    }
}

#Preview {
    // Mock ViewModel and Message for Preview
    let previewViewModel = PostchainViewModel(coordinator: RESTPostchainCoordinator())
    let testMessage = Message(
        content: "Test message content",
        isUser: false,
        phases: [
            .action: "I understand you said...",
            .experience: "Based on my experience...",
            .intention: "Your intention seems to be...",
            .yield: "Here's my response..."
        ]
    )
    
    return PhaseCard(
        phase: .action,
        message: testMessage,
        isSelected: true,
        isLoading: false,
        viewModel: previewViewModel,
        messageId: testMessage.id.uuidString
    )
    .frame(height: 300)
    .padding()
}
