# PaginatedMarkdownView Merge Plan

---

## Goal

Merge `PaginatedTextView` and `UnifiedPaginatedView` into a **single, flexible `PaginatedMarkdownView`** that:

- Renders **Markdown content** with pagination.
- Supports **mixed content pages** (Markdown + search results).
- Preserves **long press context menu** for copy/select.
- Handles **deep links** via `.onOpenURL`.
- Removes separate pagination controls UI.

---

## Key Features to Merge

### From `PaginatedTextView`

- Markdown rendering with **MarkdownUI**.
- **Pagination logic** splitting text into pages.
- **Context menu** with copy/select.
- **Long press gesture** to show context menu.

### From `UnifiedPaginatedView`

- Support for **mixed content pages**:
  - Markdown text pages.
  - Pages with **search result cards**.
- Combining **text pages** and **result pages** into one sequence.

---

## Design

### 1. **PageContent Enum**

```swift
enum PageContent: Identifiable {
    case markdown(String)
    case results([UnifiedSearchResult])

    var id: String { ... }
}
```

---

### 2. **Pagination Logic**

- Split **Markdown text** into pages.
- Chunk **search results** into pages.
- Combine into a **single `[PageContent]` array**.
- Track `currentPage` and `totalPages`.

---

### 3. **Rendering**

- For `.markdown` pages:
  - Render with **MarkdownUI**.
  - Apply **custom theme** (normalize headings).
  - Use `.onOpenURL` for deep linking.
- For `.results` pages:
  - Render as **cards** or **Markdown snippets**.
  - Support future **modal previews** on tap.

---

### 4. **Context Menu**

- Attach to the **Markdown view**.
- Preserve **copy/select** options.
- Use **shared `TextSelectionManager`**.

---

### 5. **Navigation**

- **Tap right**: next page or next phase.
- **Tap left**: previous page or previous phase.
- **Swipe**: switch phase.
- **Remove** pagination controls UI.

---

## Summary

`PaginatedMarkdownView` will unify all paginated content rendering, support mixed content, deep linking, and contextual interactions, simplifying the UI and codebase.
