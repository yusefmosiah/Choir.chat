# Unified Navigation Implementation with translucent modal Deep Link Previews

---

## Goal

Enable seamless navigation of **paginated Markdown content** with **embedded deep links** that open **translucent modal previews**.

---

## Key Points

- **All phase content** is **Markdown**.
- **Pagination** is applied to this Markdown.
- **Navigation** is:
  - **Tap** to turn pages.
  - **Swipe** to switch phases.
- **Deep links** open **translucent modal overlays** with previews, not raw jumps.
- **No inline expansion** inside paginated content.
- **Remove** separate pagination controls UI.

---

## Implementation Steps

1. **Keep** the existing `.onTapGesture` on phase cards.
2. **Replace** its body with:

```swift
if currentPage < totalPages - 1 {
    currentPage += 1
} else {
    switchToNextPhase()
}
```

3. **Add** a `.simultaneousGesture` or separate `.onTapGesture` on the **left edge**:

```swift
if currentPage > 0 {
    currentPage -= 1
} else {
    switchToPreviousPhase()
}
```

4. **Keep drag gestures** for phase switching.
5. **Remove** pagination controls at the bottom.
6. **Render all content** as paginated Markdown.
7. **Intercept link taps** with `.onOpenURL`:
   - **Show translucent modal preview** of linked content.
   - Optionally, allow navigation to thread start or summary if permitted.

---

## Summary

Navigation is tap-to-page, swipe-to-phase, with **translucent modal previews** for deep links, respecting privacy and context.
