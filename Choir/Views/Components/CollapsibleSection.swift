import SwiftUI

/// A reusable collapsible section component with smooth animations
struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    let isExpanded: Binding<Bool>
    let content: () -> Content
    
    // Optional styling parameters
    var headerBackgroundColor: Color = Color.secondary.opacity(0.1)
    var headerTextColor: Color = .primary
    var contentBackgroundColor: Color = Color.clear
    var cornerRadius: CGFloat = 12
    var animationDuration: Double = 0.3
    
    init(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.isExpanded = isExpanded
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with expand/collapse button
            headerView
            
            // Collapsible content
            if isExpanded.wrappedValue {
                contentView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(contentBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: animationDuration)) {
                isExpanded.wrappedValue.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Section icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 20, height: 20)
                
                // Section title
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(headerTextColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Expand/collapse indicator
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 180 : 0))
                    .animation(.easeInOut(duration: animationDuration), value: isExpanded.wrappedValue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(headerBackgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(contentBackgroundColor)
    }
}

// MARK: - Styling Modifiers

extension CollapsibleSection {
    /// Customize header background color
    func headerBackground(_ color: Color) -> CollapsibleSection {
        var section = self
        section.headerBackgroundColor = color
        return section
    }
    
    /// Customize header text color
    func headerTextColor(_ color: Color) -> CollapsibleSection {
        var section = self
        section.headerTextColor = color
        return section
    }
    
    /// Customize content background color
    func contentBackground(_ color: Color) -> CollapsibleSection {
        var section = self
        section.contentBackgroundColor = color
        return section
    }
    
    /// Customize corner radius
    func cornerRadius(_ radius: CGFloat) -> CollapsibleSection {
        var section = self
        section.cornerRadius = radius
        return section
    }
    
    /// Customize animation duration
    func animationDuration(_ duration: Double) -> CollapsibleSection {
        var section = self
        section.animationDuration = duration
        return section
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        CollapsibleSection(
            title: "Vector Search Results",
            icon: "doc.text.magnifyingglass",
            isExpanded: .constant(true)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("This is some sample content that would be shown when the section is expanded.")
                    .font(.body)
                
                Text("It can contain multiple lines and various UI elements.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .headerBackground(Color.blue.opacity(0.1))
        
        CollapsibleSection(
            title: "Web Search Results",
            icon: "network",
            isExpanded: .constant(false)
        ) {
            Text("This content is collapsed by default.")
        }
        .headerBackground(Color.green.opacity(0.1))
        
        Spacer()
    }
    .padding()
}
