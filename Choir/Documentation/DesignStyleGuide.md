# Choir Design Style Guide

This document outlines the design principles and visual language for the Choir application, focusing on a minimal, neumorphic, glass-like interface with angular green/blue/purple gradients as accents.

## Core Design Principles

1. **Minimalism**: Focus on essential content and functionality with clean, uncluttered interfaces.
2. **Neumorphism**: Subtle shadows and highlights to create a soft, tactile feel that appears to extrude from the background.
3. **Glass/Blur Effects**: Translucent surfaces with blur effects to create depth and hierarchy.
4. **Typography-Focused**: Clear typographic hierarchy with emphasis on readability.
5. **Angular Gradients**: Distinctive green/blue/purple angular gradients as accent elements for interactive and dynamic components.

## Color Palette

### Base Colors
- **Background**: System background with transparency (opacity 0.7-0.9)
- **Text**: Primary and secondary system colors
- **Shadows**: Black with low opacity (0.05-0.15)
- **Highlights**: White with low opacity (0.2-0.3)

### Accent Gradient
- **Green** (#00C853) at 0.0 location
- **Blue** (#2196F3) at 0.25 location
- **Purple** (#9C27B0) at 0.5 location
- **Blue** (#2196F3) at 0.75 location
- **Green** (#00C853) at 1.0 location

### Status Colors
- **Error/Cancel**: Red (#F44336) with angular gradient to orange
- **Warning**: Orange (#FF9800) with reduced opacity
- **Success**: Green (#4CAF50) with reduced opacity

## Typography

- **Headings**: System font, medium weight, sizes 20-42pt
- **Body Text**: System font, regular weight, sizes 14-16pt
- **Captions/Secondary**: System font, light weight, sizes 12-14pt
- **Emphasis**: Achieved through weight and size rather than color when possible

## Component Styles

### Cards & Containers

```swift
// Neumorphic glass card with gradient background
VStack {
    // Content here
}
.padding(.vertical, 30)
.padding(.horizontal, 25)
.background(
    ZStack {
        // Angular gradient shadow (optional, for active/loading states)
        RoundedRectangle(cornerRadius: 20)
            .fill(
                AngularGradient(
                    gradient: Gradient(stops: [
                        .init(color: .green, location: 0.0),
                        .init(color: .blue, location: 0.25),
                        .init(color: .purple, location: 0.5),
                        .init(color: .blue, location: 0.75),
                        .init(color: .green, location: 1.0),
                    ]),
                    center: .center,
                    angle: .degrees(gradientRotation)
                )
            )
            .blur(radius: 8)
            .opacity(0.7)
            .scaleEffect(1.05)
            .offset(y: 2)
        
        // Glass card background with neumorphic effect
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(UIColor.systemBackground).opacity(0.7))
            // Add a subtle inner shadow for depth
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .blur(radius: 1)
                    .offset(x: 0, y: 1)
                    .mask(RoundedRectangle(cornerRadius: 20).fill(LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )))
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            .blur(radius: 0.5)
    }
)
.overlay(
    RoundedRectangle(cornerRadius: 20)
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.3), Color.gray.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 1
        )
        .blur(radius: 0.5)
)
```

### Buttons

```swift
// Standard button with gradient background (for primary actions)
Button(action: {}) {
    Text("Button Text")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
}
.background(
    ZStack {
        // Angular gradient background
        RoundedRectangle(cornerRadius: 14)
            .fill(
                AngularGradient(
                    gradient: Gradient(stops: [
                        .init(color: .green, location: 0.0),
                        .init(color: .blue, location: 0.25),
                        .init(color: .purple, location: 0.5),
                        .init(color: .blue, location: 0.75),
                        .init(color: .green, location: 1.0),
                    ]),
                    center: .center
                )
            )
            .blur(radius: 4)
            .opacity(0.8)
        
        // Glass overlay
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(UIColor.systemBackground).opacity(0.3))
            .blur(radius: 0.5)
    }
)

// Secondary button with stroke (for secondary actions)
Button(action: {}) {
    Text("Button Text")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
}
.background(
    RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        .blur(radius: 1)
)
```

### Input Fields

```swift
// Text input with neumorphic styling
ZStack(alignment: .topLeading) {
    // Placeholder text when empty
    if text.isEmpty {
        Text("Placeholder text...")
            .foregroundColor(.gray.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }

    // Actual text editor
    TextEditor(text: $text)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
}
.padding(.vertical, 4)
.background(
    ZStack {
        // Glass background with neumorphic effect
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(UIColor.systemBackground).opacity(0.7))
            // Add a subtle inner shadow for depth
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .blur(radius: 1)
                    .offset(x: 0, y: 1)
                    .mask(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )))
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
)
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.3), Color.gray.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 1
        )
        .blur(radius: 0.5)
)
```

## Animation Guidelines

### Gradient Rotation

For dynamic elements that need to indicate processing or activity:

```swift
// Animation state
@State private var gradientRotation: Double = 0
@State private var rotationTimer: Timer?

// Start rotation animation
private func startRotationTimer() {
    // Stop any existing timer first
    stopRotationTimer()

    // Reset rotation to 0
    gradientRotation = 0

    // Create a new timer that updates the rotation angle
    rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [self] _ in
        // Update rotation on the main thread
        DispatchQueue.main.async {
            // Increment rotation by 3 degrees each time for faster rotation
            withAnimation(.linear(duration: 0.02)) {
                self.gradientRotation = (self.gradientRotation + 3).truncatingRemainder(dividingBy: 360)
            }
        }
    }
}

private func stopRotationTimer() {
    rotationTimer?.invalidate()
    rotationTimer = nil
}
```

### Transitions

- Use `.opacity` transitions for elements appearing/disappearing
- Use `.easeInOut` with short durations (0.15-0.2s) for size changes
- Use `.spring` with medium response (0.3s) and dampingFraction (0.8) for more natural movements

## Accessibility Considerations

- Maintain sufficient contrast between text and backgrounds
- Ensure interactive elements have adequate touch targets (minimum 44x44 points)
- Support dynamic type for text elements
- Test with VoiceOver and other accessibility features
- Ensure the design works well in both light and dark mode

## Implementation Examples

### OnboardingView Authentication Card

The authentication card in the OnboardingView demonstrates the core principles of this design language:

1. Minimal, typography-focused content
2. Neumorphic glass card with subtle shadows and highlights
3. Angular green/blue/purple gradient as a dynamic background element
4. Animated rotation to indicate processing

### ThreadInputBar

The ThreadInputBar implements these design principles for an interactive input component:

1. Glass-like text input field with neumorphic styling
2. Circular send button with the signature angular gradient
3. Animated cancel button with red/orange gradient during processing
4. Subtle glass-like notifications for warnings and status messages

## Best Practices

1. **Consistency**: Apply these design principles consistently across the app
2. **Performance**: Be mindful of blur effects and animations on older devices
3. **Simplicity**: Keep interfaces clean and focused on content
4. **Feedback**: Provide clear visual feedback for user interactions
5. **Adaptability**: Ensure designs work well across different device sizes and orientations
