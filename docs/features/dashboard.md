# Choir Project Dashboard

---

## Current Focus: Unified Markdown + Deep Linking + Simplified Navigation

---

## Feature Checklist

### ✅ Modularize Models
- Split 700+ line `ChoirModels.swift` into smaller files

### ✅ Unified Markdown Rendering
- Convert all phase content (text, vectors, web) to Markdown
- Inject deep links inside Markdown
- Render with MarkdownUI

### 🔲 Merge Pagination Views
- Replace `PaginatedTextView` and `UnifiedPaginatedView` with one `PaginatedMarkdownView`

### 🔲 Simplify Navigation
- Tap to turn page
- Swipe to switch phase
- Remove pagination controls UI
- Implement tap gesture logic (page turn or phase switch)

### 🔲 Deep Linking
- Use `.onOpenURL` to intercept all links
- Open internal deep links (e.g., `choir://thread/...`)
- Open external URLs in Safari

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
3. Deep linking polish
4. Shift focus to rewards + tokens

---

_Last updated: April 10, 2025_
