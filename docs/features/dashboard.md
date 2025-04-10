# Choir Project Dashboard

---

## Critical Focus

- **Unified Markdown rendering** for all phase content.
- **Deep links embedded in Markdown**.
- **Deep links open modal previews**, not raw jumps.
- **Pagination** for reading flow.
- **Tap to turn page, swipe to switch phase**.
- **Remove pagination controls UI**.
- **Respect privacy and access**.
- **Prepare for thread contracts, rewards, and sharing**.

---

## Feature Checklist

### ✅ Modularize Models
- Split 700+ line `ChoirModels.swift` into smaller files

### ✅ Unified Markdown Rendering
- Convert all phase content to Markdown
- Inject deep links inside Markdown
- Render with MarkdownUI
- Customize MarkdownUI theme (normalize headings)

### 🔲 Merge Pagination Views
- Replace `PaginatedTextView` and `UnifiedPaginatedView` with one `PaginatedMarkdownView`

### 🔲 Simplify Navigation
- Tap to turn page
- Swipe to switch phase
- Remove pagination controls UI
- Implement tap gesture logic (page turn or phase switch)

### 🔲 Deep Linking
- Use `.onOpenURL` to intercept all links
- Open **modal previews** for deep links
- Avoid deep linking into arbitrary thread positions
- Navigate to thread start or summary if permitted

### 🔲 Rewards & Token Integration
- Connect to Sui blockchain
- Calculate rewards
- Issue tokens

### 🔲 Speech & Audio (Future)
- Stream Markdown content as speech
- Voice commands for navigation
- Prepare for screenless interfaces (watch, AirPods)

---

## Progress Summary

- **Models Modularized:** 100%
- **Markdown Unification:** 80%
- **Deep Linking:** 70%
- **Navigation Simplification:** 50%
- **Rewards/Token:** 0%
- **Speech/Audio:** 0%

---

## Next Priorities

1. Merge pagination views
2. Finalize tap/drag navigation
3. Implement modal previews for deep links
4. Shift focus to rewards + tokens

---

_Last updated: April 10, 2025_
