# Choir Design Style Guide

This document outlines the design principles and visual language for the Choir application, focusing on a carbon fiber kintsugi aesthetic with black/charcoal woven textures, worn patina effects, and gold/silver/platinum metallic accents representing repair and resilience.

## Core Design Principles

1. **Industrial Minimalism**: Focus on essential content with clean, purposeful interfaces that embrace the beauty of worn, functional materials.
2. **Carbon Fiber Texture**: Woven carbon fiber patterns as the foundational texture, creating depth through subtle directional weaving.
3. **Kintsugi Philosophy**: Embrace imperfection and repair as beauty - metallic veining and crack patterns that highlight resilience and growth.
4. **Typography-Focused**: Clear typographic hierarchy with emphasis on readability against dark, textured backgrounds.
5. **Metallic Accents**: Gold, silver, and platinum gradients as accent elements representing value, repair, and precious connections.

## Color Palette

### Base Colors
- **Background**: Deep charcoal (#1a1a1a) with carbon fiber weave texture
- **Surface**: Matte black (#0d0d0d) with subtle directional grain
- **Text Primary**: Platinum white (#f5f5f5) with subtle metallic sheen
- **Text Secondary**: Silver gray (#a8a8a8) with muted luminosity
- **Shadows**: Pure black with medium opacity (0.3-0.6) for depth
- **Highlights**: Warm white (#fafafa) with very low opacity (0.1-0.2)

### Metallic Accent Gradients
- **Gold Kintsugi** (#ffd700 → #b8860b): Primary repair lines and value indicators
- **Silver Veining** (#c0c0c0 → #808080): Secondary connections and pathways
- **Platinum Highlights** (#e5e4e2 → #b8b8b8): Premium accents and active states
- **Copper Patina** (#b87333 → #8b4513): Aged elements and worn surfaces

### Status Colors
- **Error/Damage**: Deep red (#8b0000) with copper patina gradient
- **Warning/Caution**: Amber (#ffbf00) with gold accent
- **Success/Repair**: Emerald (#50c878) with silver veining

## Typography

- **Headings**: System font, medium weight, sizes 20-42pt with subtle metallic sheen
- **Body Text**: System font, regular weight, sizes 14-16pt in platinum white
- **Captions/Secondary**: System font, light weight, sizes 12-14pt in silver gray
- **Emphasis**: Achieved through metallic gradients and weight rather than bright colors

## Component Styles

### Cards & Containers

```swift
// Carbon fiber card with kintsugi metallic veining
VStack {
    // Content here
}
.padding(.vertical, 30)
.padding(.horizontal, 25)
.background(
    ZStack {
        // Carbon fiber base texture
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(red: 0.05, green: 0.05, blue: 0.05)) // Deep charcoal
            .overlay(
                // Subtle carbon fiber weave pattern
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0.8), location: 0.0),
                                .init(color: Color.gray.opacity(0.1), location: 0.5),
                                .init(color: Color.black.opacity(0.8), location: 1.0),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            )

        // Kintsugi metallic veining (for active/special states)
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), location: 0.0), // Gold
                        .init(color: Color(red: 0.75, green: 0.75, blue: 0.75).opacity(0.6), location: 0.5), // Silver
                        .init(color: Color(red: 0.9, green: 0.89, blue: 0.89).opacity(0.7), location: 1.0), // Platinum
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blur(radius: 1)
            .opacity(0.6)
    }
)
.shadow(color: Color.black.opacity(0.6), radius: 15, x: 0, y: 8)
```

### Buttons

```swift
// Primary button with metallic kintsugi accent (for primary actions)
Button(action: {}) {
    Text("Button Text")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.96)) // Platinum white
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
}
.background(
    ZStack {
        // Carbon fiber base
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(red: 0.08, green: 0.08, blue: 0.08)) // Matte black

        // Metallic gradient overlay
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), location: 0.0), // Gold
                        .init(color: Color(red: 0.75, green: 0.75, blue: 0.75).opacity(0.6), location: 0.5), // Silver
                        .init(color: Color(red: 0.9, green: 0.89, blue: 0.89).opacity(0.7), location: 1.0), // Platinum
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.overlay)
            .opacity(0.9)
    }
)
.shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)

// Secondary button with worn carbon fiber texture (for secondary actions)
Button(action: {}) {
    Text("Button Text")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(red: 0.66, green: 0.66, blue: 0.66)) // Silver gray
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
}
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(Color(red: 0.05, green: 0.05, blue: 0.05)) // Deep charcoal
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.4), lineWidth: 1) // Silver stroke
        )
)
.shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
```

### Input Fields

```swift
// Text input with carbon fiber texture and metallic focus accent
ZStack(alignment: .topLeading) {
    // Placeholder text when empty
    if text.isEmpty {
        Text("Placeholder text...")
            .foregroundColor(Color(red: 0.66, green: 0.66, blue: 0.66).opacity(0.6)) // Silver gray
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }

    // Actual text editor
    TextEditor(text: $text)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.96)) // Platinum white
}
.padding(.vertical, 4)
.background(
    ZStack {
        // Carbon fiber base
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(red: 0.05, green: 0.05, blue: 0.05)) // Deep charcoal
            .overlay(
                // Subtle directional grain pattern
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0.9), location: 0.0),
                                .init(color: Color.gray.opacity(0.05), location: 0.5),
                                .init(color: Color.black.opacity(0.9), location: 1.0),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .blendMode(.overlay)
            )
    }
)
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.3), // Silver
                    Color(red: 0.3, green: 0.3, blue: 0.3).opacity(0.1)  // Dark gray
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 1
        )
)
.shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
```

## Animation Guidelines

### Metallic Shimmer Animation

For dynamic elements that need to indicate processing or activity, use subtle metallic shimmer effects:

```swift
// Animation state
@State private var shimmerOffset: CGFloat = -200
@State private var shimmerTimer: Timer?

// Start shimmer animation
private func startShimmerAnimation() {
    // Stop any existing timer first
    stopShimmerAnimation()

    // Reset shimmer position
    shimmerOffset = -200

    // Create a subtle shimmer effect
    shimmerTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [self] _ in
        DispatchQueue.main.async {
            withAnimation(.linear(duration: 0.05)) {
                self.shimmerOffset += 8
                if self.shimmerOffset > 400 {
                    self.shimmerOffset = -200
                }
            }
        }
    }
}

private func stopShimmerAnimation() {
    shimmerTimer?.invalidate()
    shimmerTimer = nil
}

// Shimmer overlay for active elements
.overlay(
    Rectangle()
        .fill(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.clear, location: 0.0),
                    .init(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), location: 0.5), // Gold
                    .init(color: Color.clear, location: 1.0),
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .offset(x: shimmerOffset)
        .mask(RoundedRectangle(cornerRadius: 16))
)
```

### Transitions

- Use `.opacity` transitions for elements appearing/disappearing with slower, more deliberate timing
- Use `.easeInOut` with medium durations (0.25-0.35s) for size changes to feel more substantial
- Use `.spring` with slower response (0.4s) and higher dampingFraction (0.9) for weighty, industrial feel

## Accessibility Considerations

- Maintain high contrast between platinum/silver text and dark carbon fiber backgrounds
- Ensure interactive elements have adequate touch targets (minimum 44x44 points)
- Support dynamic type for text elements with appropriate metallic color adjustments
- Test with VoiceOver and other accessibility features, ensuring metallic accents don't interfere
- Design primarily for dark mode aesthetic while maintaining readability

## Implementation Examples

### OnboardingView Authentication Card

The authentication card demonstrates the carbon fiber kintsugi design principles:

1. Industrial minimalism with typography-focused content
2. Carbon fiber textured card with deep shadows and metallic highlights
3. Gold kintsugi veining as dynamic background element indicating value and connection
4. Subtle metallic shimmer animation to indicate processing

### ThreadInputBar

The ThreadInputBar implements carbon fiber kintsugi principles for interactive input:

1. Carbon fiber textured input field with worn, patina'd styling
2. Circular send button with gold/silver/platinum metallic gradient
3. Animated copper patina button with deep red gradient during processing
4. Subtle metallic notifications with kintsugi-style crack patterns for status messages

## Best Practices

1. **Consistency**: Apply carbon fiber kintsugi principles consistently across the app
2. **Performance**: Be mindful of texture overlays and metallic effects on older devices
3. **Industrial Beauty**: Embrace the beauty of worn, functional materials and repair
4. **Feedback**: Provide clear metallic visual feedback that feels substantial and valuable
5. **Adaptability**: Ensure carbon fiber textures scale appropriately across device sizes
6. **Kintsugi Philosophy**: Use metallic accents to highlight connections, repairs, and growth rather than perfection
