# Carousel UI Pattern

VERSION carousel_ui:
invariants: {
"User-friendly navigation",
"Clear phase distinction",
"Responsive design"
}
assumptions: {
"Using SwiftUI",
"Phases are sequential",
"Support for gestures"
}
docs_version: "0.1.0"

## Introduction

The Carousel UI Pattern provides an intuitive way for users to navigate through the different phases of the Chorus Cycle by swiping between views, creating a seamless and engaging experience.

## Design Principles

- **Intuitive Navigation**

  - Users can swipe left or right to move between phases.
  - Supports natural gesture interactions familiar to iOS users.

- **Visual Feedback**

  - Each phase is distinctly represented, enhancing user understanding.
  - Progress indicators guide users on their journey.

- **Responsive Animations**

  - Smooth transitions improve perceived performance.
  - Visual cues indicate loading states and interactive elements.

- **Accessibility**
  - Design accommodates various screen sizes and orientations.
  - Supports VoiceOver and other accessibility features.

## Implementation Details

### 1. SwiftUI `TabView` with `PageTabViewStyle`

- **Creating the Carousel**

  ````swift
  import SwiftUI

  struct ChorusCarouselView: View {
      @State private var selectedPhase = 0
      let phases = ["Action", "Experience", "Intention", "Observation", "Understanding", "Yield"]

      var body: some View {
          TabView(selection: $selectedPhase) {
              ForEach(0..<phases.count) { index in
                  PhaseView(phaseName: phases[index])
                      .tag(index)
              }
          }
          .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
          .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .interactive))
      }
  }  ```

  ````

- **Phase View**

  ````swift
  struct PhaseView: View {
      let phaseName: String

      var body: some View {
          VStack {
              Text(phaseName)
                  .font(.largeTitle)
                  .bold()
              // Content specific to the phase
          }
          .padding()
      }
  }  ```
  ````

### 2. Gesture Support

- **Custom Gestures**

  While `TabView` with `PageTabViewStyle` handles basic swipe gestures, you may want to add custom gestures for additional controls.

  ````swift
  .gesture(
      DragGesture()
          .onEnded { value in
              // Handle drag gestures
          }
  )  ```
  ````

### 3. Loading Indicators

- **Phase-Specific Loading**

  ````swift
  struct PhaseView: View {
      let phaseName: String
      @State private var isLoading = false

      var body: some View {
          VStack {
              if isLoading {
                  ProgressView("Loading \(phaseName)...")
              } else {
                  // Display content
              }
          }
          .onAppear {
              // Start loading content
              isLoading = true
              loadContent()
          }
      }

      func loadContent() {
          // Simulate loading
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              isLoading = false
          }
      }
  }  ```
  ````

### 4. Accessibility Features

- **VoiceOver Support**

  ````swift
  .accessibilityElement(children: .contain)
  .accessibility(label: Text("Phase \(phaseName)"))  ```

  ````

- **Dynamic Type**

  Use relative font sizes to support dynamic type settings.

  ````swift
  .font(.title)  ```
  ````

### 5. Customization

- **Page Indicators**

  Customize the page indicators to match the app's theme.

  ````swift
  .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))  ```

  ````

- **Animations**

  Apply animations to transitions or loading states.

  ````swift
  .animation(.easeInOut(duration: 0.3))  ```
  ````

## User Experience Considerations

- **Progress Awareness**

  - Indicate which phase the user is on and how many are left.
  - Use labels or progress bars.

- **State Preservation**

  - Retain user inputs or interactions when navigating between phases.
  - Use `@State` or data models to store state.

- **Error Handling**
  - Inform the user of any issues loading content.
  - Provide options to retry or seek help.

## Advantages

- **Engagement**

  - Interactive elements keep users engaged.
  - Swiping is more engaging than tapping buttons to proceed.

- **Clarity**

  - Clearly separates content associated with each phase.
  - Reduces cognitive load by focusing on one phase at a time.

- **Aesthetics**
  - Modern and sleek design aligns with current UI trends.
  - Enhances the perceived quality of the app.

## Potential Challenges

- **Content Overload**

  - Ensure each phase view is not overcrowded.
  - Break down information into digestible chunks.

- **Performance**

  - Optimize content loading to prevent lag during swiping.
  - Load heavy content asynchronously.

- **Usability on Different Devices**
  - Test on various iPhone and iPad models.
  - Ensure UI scales appropriately.

---

By adopting the Carousel UI Pattern, we enhance the user experience, making the navigation through the Chorus Cycle intuitive, engaging, and visually appealing.
