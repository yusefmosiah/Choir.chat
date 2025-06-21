# Choir Design Style Guide: Carbon Fiber Kintsugi

This document outlines the design principles and visual language for the Choir application, centered on the "Carbon Fiber Kintsugi" theme. This theme embodies **antifragile timeless luxury married with high-tech materiality**. It emphasizes resilience, the beauty of imperfection (as highlighted by repair), and enduring value through advanced materials.

## Core Design Principles

1.  **Antifragile Aesthetics**: Design elements that not only withstand stress but become more interesting and beautiful through perceived wear and repair (e.g., kintsugi cracks on carbon fiber). This signals resilience and history.
2.  **High-Tech Materiality**: Prominent use of carbon fiber textures, not just as a visual pattern, but suggesting the material's inherent strength, lightness, and modernity. Accents of other advanced materials like brushed or anodized aluminum, and technical ceramics.
3.  **Timeless Luxury**: A refined and sophisticated palette, focusing on deep, rich tones complemented by precious metal accents (especially gold, antique gold, and subtle platinum/silver). Minimalism in layout, allowing the materials and kintsugi details to be focal points.
4.  **Kintsugi Philosophy**: The Japanese art of repairing broken pottery with lacquer dusted or mixed with powdered gold, silver, or platinum. Metaphorically, this represents embracing flaws and imperfections, and highlighting them as a valuable part of an object's history and strength. In our design, kintsugi lines will be used as accentual, meaningful graphics.
5.  **Precision & Craftsmanship**: Clean lines, sharp typography, and meticulously crafted details that reflect the precision of high-tech manufacturing and the care of artisanal repair.
6.  **Subtle Illumination**: Lighting that accentuates textures and material properties. Soft, focused glows on kintsugi lines, and gentle highlights on carbon fiber weaves, rather than overt holographic effects.

## Color Palette

### Primary Palette: Deep & Rich
-   **Carbon Black**: `#0C0C0C` (Deep, matte carbon fiber base)
-   **Obsidian Black**: `#141414` (Slightly lighter, for layered surfaces, suggesting depth in carbon weave)
-   **Charcoal Grey**: `#222222` (Dark grey for subtle variations and UI elements)
-   **Graphite**: `#333333` (Mid-dark grey for secondary text and UI components)

### Accent Palette: Kintsugi & High-Tech Metals
-   **Kintsugi Gold**: `#B08D57` (A rich, slightly antique gold for kintsugi lines and primary accents)
-   **Molten Gold**: `#CFB53B` (Brighter gold for highlights and interactive states)
-   **Brushed Platinum**: `#D0D0D5` (Subtle, cool metallic for secondary accents and text highlights)
-   **Anodized Bronze**: `#8C7853` (A darker, warmer metallic accent)

### Text & UI Colors
-   **Text Primary**: `#EAEAEA` (Off-white, for high readability on dark backgrounds)
-   **Text Secondary**: `#A0A0A0` (Light grey for less emphasized text)
-   **Subtle Gold Text**: `#B08D57` (For special highlights or call-to-actions, use sparingly)

### Status & Feedback (Inspired by material states)
-   **Error/Alert**: Deep Amber/Burnt Orange `#C77700` (Suggesting heat or warning, less "digital red")
-   **Warning/Caution**: Warm Gold/Brass `#D4A017` (A cautionary, less alarming gold)
-   **Success/Confirm**: Muted Jade Green/Patina `#6A8A82` (A subtle, natural green, suggesting stability)

## Typography

-   **Primary Font Family**: A modern, geometric sans-serif font that evokes precision and clarity. Examples: `Inter`, `Manrope`, `Neue Haas Grotesk Display`.
    -   **Headings**: Medium to Bold weight, sizes 24-48pt. Can incorporate subtle gold (`#B08D57`) for key titles or have a kintsugi-line underscore.
    -   **Body Text**: Regular weight, sizes 15-17pt in Text Primary (`#EAEAEA`) for optimal readability.
    -   **Captions/Secondary**: Light or Regular weight, sizes 12-14pt in Text Secondary (`#A0A0A0`).
-   **Emphasis**: Achieved through font weight changes, subtle color shifts (e.g., to Subtle Gold Text or Brushed Platinum for a highlight), or kintsugi-inspired underlines/rules. Avoid overly bright or distracting emphasis colors.

## Imagery & Iconography Guidelines

-   **Carbon Fiber Textures**:
    -   Use high-resolution, realistic carbon fiber patterns (twill weave, plain weave, forged carbon).
    -   Textures should appear integrated, not just overlaid. Suggest depth and tactile quality.
    -   Vary the scale and finish (matte, satin) for different UI elements.
-   **Kintsugi Patterns**:
    -   Abstract, elegant gold lines that resemble kintsugi repairs.
    -   Should feel organic and purposeful, as if repairing or highlighting a feature.
    -   Can be used as dividers, borders, accents on cards, or subtle background elements.
    -   Avoid overly complex or cluttered kintsugi patterns. They should add grace, not noise.
-   **Iconography**:
    -   Clean, line-style icons with a consistent stroke weight.
    -   Primary icon color: Text Secondary (`#A0A0A0`).
    -   Active/selected state: Kintsugi Gold (`#B08D57`) or Brushed Platinum (`#D0D0D5`).
    -   Icons should feel precise and high-tech, matching the overall aesthetic.

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
        // Carbon fiber base texture (using new palette)
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(hex: "#0C0C0C")) // Carbon Black
            .overlay(
                // Subtle carbon fiber weave pattern
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0.7), location: 0.0), // Deeper shadow
                                .init(color: Color(hex: "#141414").opacity(0.2), location: 0.5), // Obsidian highlight
                                .init(color: Color.black.opacity(0.7), location: 1.0),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            )

        // Kintsugi metallic veining (using new gold)
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#B08D57").opacity(0.9), location: 0.0), // Kintsugi Gold
                        .init(color: Color(hex: "#CFB53B").opacity(0.7), location: 0.5), // Molten Gold
                        .init(color: Color(hex: "#B08D57").opacity(0.8), location: 1.0), // Kintsugi Gold
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5 // Slightly thicker for more presence
            )
            .blur(radius: 0.5) // Sharper blur for defined lines
            .opacity(0.75) // More visible
    }
)
.shadow(color: Color.black.opacity(0.7), radius: 20, x: 0, y: 10) // Deeper shadow
```

### Buttons

```swift
// Primary button with Kintsugi Gold accent
Button(action: {}) {
    Text("Primary Action")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(hex: "#EAEAEA")) // Text Primary
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16) // Slightly more padding
}
.background(
    ZStack {
        // Matte carbon fiber base
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(hex: "#141414")) // Obsidian Black

        // Kintsugi Gold line accent on hover/active (example, actual implementation might differ)
        // For static, could be a border or subtle inset line
        RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "#B08D57"), lineWidth: 1.5)
            .opacity(0.8) // Subtle border
    }
)
.shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: 5)

// Secondary button with brushed metallic feel
Button(action: {}) {
    Text("Secondary Action")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(hex: "#A0A0A0")) // Text Secondary
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
}
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(Color(hex: "#222222")) // Charcoal Grey
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#333333").opacity(0.7), lineWidth: 1) // Graphite stroke
        )
)
.shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 3)
```

### Input Fields

```swift
// Text input with carbon fiber texture and gold focus accent
@State private var text: String = ""
var isFocused: Bool = false // Example state for focus

ZStack(alignment: .topLeading) {
    if text.isEmpty && !isFocused { // Show placeholder only if not focused and empty
        Text("Enter text...")
            .foregroundColor(Color(hex: "#A0A0A0").opacity(0.6)) // Text Secondary
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
    }

    TextEditor(text: $text)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .foregroundColor(Color(hex: "#EAEAEA")) // Text Primary
}
.frame(minHeight: 48) // Ensure a minimum height
.padding(.vertical, 4)
.background(
    ZStack {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(hex: "#0C0C0C")) // Carbon Black
            .overlay(
                // Subtle directional grain pattern
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0.8), location: 0.0),
                                .init(color: Color(hex: "#141414").opacity(0.1), location: 0.5),
                                .init(color: Color.black.opacity(0.8), location: 1.0),
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
            isFocused ? Color(hex: "#B08D57") : Color(hex: "#333333").opacity(0.5), // Kintsugi Gold on focus
            lineWidth: isFocused ? 1.5 : 1 // Thicker border on focus
        )
)
.shadow(color: Color.black.opacity(isFocused ? 0.5 : 0.4), radius: isFocused ? 8 : 6, x: 0, y: isFocused ? 4 : 3)
```

## Animation Guidelines

### Kintsugi Reveal Animation

For dynamic elements or state changes, kintsugi lines can "draw" themselves or subtly glow:

```swift
// Animation state for kintsugi line drawing
@State private var kintsugiProgress: CGFloat = 0

// Example of a kintsugi line being drawn
Path { path in
    path.move(to: CGPoint(x: 0, y: 50))
    path.addLine(to: CGPoint(x: 100, y: 50))
    // Add more complex path segments
}
.trim(from: 0, to: kintsugiProgress) // Animate the trim
.stroke(Color(hex: "#B08D57"), lineWidth: 2)
.onAppear {
    withAnimation(.easeInOut(duration: 1.5)) {
        kintsugiProgress = 1.0
    }
}

// Subtle glow animation for kintsugi accents
@State private var isGlowing: Bool = false
// ... in view body
Color(hex: "#B08D57")
    .opacity(isGlowing ? 1.0 : 0.7)
    .shadow(color: isGlowing ? Color(hex: "#CFB53B").opacity(0.7) : Color.clear, radius: isGlowing ? 8 : 0, x: 0, y: 0)
    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isGlowing)
    .onAppear { isGlowing = true }

```
### Material Shimmer & Texture Focus

-   Instead of broad holographic shimmers, use subtle lighting shifts that highlight the carbon fiber weave or metallic surfaces.
-   Focus changes can subtly sharpen or deepen texture appearance.

### Transitions

-   Use `.opacity` transitions for elements appearing/disappearing with smooth, deliberate timing (0.3-0.4s).
-   Use `.easeInOut` with medium durations (0.3s) for size and position changes.
-   Spring animations should feel grounded and responsive, reflecting high-quality engineering. `response: 0.4, dampingFraction: 0.8`.

## Accessibility Considerations

-   **Contrast**: Ensure sufficient contrast between text (e.g., `#EAEAEA`) and dark backgrounds (e.g., `#0C0C0C`). Test with WCAG guidelines. Kintsugi Gold (`#B08D57`) on Carbon Black (`#0C0C0C`) should be checked, especially for text.
-   **Focus Indicators**: Use clear, visible focus indicators for interactive elements, potentially using the Kintsugi Gold or a thickened border as shown in Input Fields.
-   **Dynamic Type**: Support dynamic type. Ensure text remains legible and UI elements adapt gracefully.
-   **Reduce Motion**: Provide options to reduce animations, especially complex kintsugi line drawing or glowing effects, for users sensitive to motion.
-   **Readability**: The chosen geometric sans-serif font should have excellent legibility at various sizes.

## Implementation Examples

### OnboardingView Authentication Card

The authentication card should embody the Carbon Fiber Kintsugi theme:

1.  **Minimalist Layout**: Typography-focused content on a clean carbon fiber background.
2.  **Material Integrity**: A rich, matte carbon fiber texture for the card itself, with deep, soft shadows suggesting solidity.
3.  **Kintsugi Accent**: A single, elegant kintsugi gold line could run along one edge or subtly "repair" a corner, symbolizing the strength found in connection or restoration of identity.
4.  **Focused Lighting**: Subtle gradients or edge highlights that make the carbon fiber feel three-dimensional and the gold line catch the light.

### ThreadInputBar

The ThreadInputBar should reflect refined, high-tech materiality:

1.  **Input Field**: A dark carbon fiber textured input field, perhaps with a very subtle weave pattern. Focus state highlighted with a Kintsugi Gold border.
2.  **Send Button**: A circular button with a dark brushed metal (Anodized Bronze or Graphite) appearance, with the send icon in Kintsugi Gold or Brushed Platinum. Active/pressed state could show a subtle glow or depression effect.
3.  **Status Messages**: Important notifications or confirmations could appear with a thin Kintsugi Gold underline or a small, iconic kintsugi mark.

## Best Practices

1.  **Authenticity**: Materials should feel authentic. Carbon fiber should look like carbon fiber, not just a pattern. Gold should have a metallic sheen.
2.  **Subtlety**: Kintsugi elements are accents, not dominant features. They should add meaning and elegance, not clutter.
3.  **Meaningful Application**: Use kintsugi patterns where they can metaphorically represent connection, repair, strength, or valuable history.
4.  **Performance**: Optimize textures and effects. High-resolution carbon fiber and complex lines can be performance-intensive.
5.  **Hierarchy**: Use the richness of materials and accents to guide the user's eye and establish visual hierarchy. Kintsugi Gold is a primary accent; use it for the most important elements.
6.  **Consistency**: Apply the Carbon Fiber Kintsugi principles consistently across all UI elements and views for a cohesive experience.

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
