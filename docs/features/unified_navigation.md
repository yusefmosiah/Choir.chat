# Unified Navigation with translucent modal Previews for Deep Links

---

## Objective

Enable seamless navigation of **paginated Markdown content** with **embedded deep links** that open **translucent modal previews** instead of jumping.

---

## Navigation Behavior

| Gesture | When | Action |
|---------|-------|--------|
| **Tap Right Edge** | Not last page | Next page |
| **Tap Right Edge** | Last page | Next phase, page 0 |
| **Tap Left Edge** | Not first page | Previous page |
| **Tap Left Edge** | First page | Previous phase, last page |
| **Swipe Left/Right** | Always | Switch phase |
| **Tap Link** | Always | Show translucent modal preview of linked content |

---

## Deep Link Handling

- **No direct navigation** into arbitrary thread positions.
- **Show translucent modal previews** of search results or citations.
- Optionally, allow **navigation to thread start** or summary if permitted.

---

## Benefits

- **Preserves reading flow** and pagination.
- **Respects privacy** and access control.
- **Simplifies UX** with contextual previews.
- **Prepares for future** thread contracts and sharing features.

---

## Summary

Navigation is tap-to-page, swipe-to-phase, with **translucent modal previews** for deep links instead of raw jumps.
