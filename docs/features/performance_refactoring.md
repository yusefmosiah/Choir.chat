# Performance Refactoring Plan: Drag Animation Optimization

## Context

- The drag animation for selecting phases in `PostchainView.swift` causes CPU usage spikes >100%.
- Root cause identified: **Animating every incremental drag update** using `withAnimation(.interactiveSpring())` inside `.onChanged` of a `DragGesture`.
- This results in **continuous, costly animations** during the entire drag gesture.

---

## Goals

- **Eliminate continuous animations during drag.**
- **Only animate the final snap/settle position after drag ends.**
- **Reduce CPU usage and improve UI responsiveness.**

---

## Current Implementation (Problematic)

```swift
DragGesture()
    .onChanged { value in
        withAnimation(.interactiveSpring()) {
            // Updates drag offset here
        }
    }
    .onEnded { value in
        handleDragEnd(value: value, cardWidth: cardWidth)
    }
```

- **Issue:** `withAnimation` wraps every incremental drag update, causing continuous expensive animations.

---

## Refactoring Plan

### 1. **Remove animation from `.onChanged`**

- Update drag offset **without any animation** during drag.
- This ensures UI updates immediately, without triggering costly animations.

**Change to:**

```swift
DragGesture()
    .onChanged { value in
        // Directly update drag offset, no animation
        self.dragOffset = value.translation.width
    }
```

---

### 2. **Animate only on drag end**

- When the user lifts their finger, animate the card snapping to its final position.
- Wrap this **only in `.onEnded`**:

```swift
.onEnded { value in
    withAnimation(.interactiveSpring()) {
        self.dragOffset = computeFinalOffset(value)
    }
}
```

- `computeFinalOffset(value)` should determine the nearest snap point or target offset.

---

### 3. **Optional: Disable implicit animations during drag**

- If other parts of the view tree have implicit animations, consider disabling them during drag updates:

```swift
.withTransaction { transaction in
    transaction.disablesAnimations = true
    self.dragOffset = value.translation.width
}
```

---

### 4. **Profile and Tune**

- Use **Instruments (Time Profiler, SwiftUI)** to verify reduced CPU usage.
- Adjust spring parameters for desired snap feel without over-animating.
- Confirm UI remains smooth and responsive during drag.

---

## Summary

| Before | After |
| --- | --- |
| Animate **every drag delta** | Animate **only on drag end** |
| High CPU usage | Lower CPU usage |
| Laggy drag | Smooth drag |

---

## Expected Impact

- **Significantly reduced CPU usage during drag gestures.**
- **Smoother, more responsive UI.**
- **Animations feel more natural, only on release.**

---

## References

- [Apple WWDC: Building Smooth Animations](https://developer.apple.com/videos/play/wwdc2020/10019/)
- [SwiftUI Performance Tips](https://swiftwithmajid.com/2020/05/27/swiftui-performance-tips-and-tricks/)
- [Disabling Animations in SwiftUI](https://www.hackingwithswift.com/quick-start/swiftui/how-to-disable-animation-for-specific-changes)
