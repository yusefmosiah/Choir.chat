# Checklist: Refactor Search Results to Markdown

This checklist outlines the steps required to refactor the display of vector and web search results to integrate them directly into the Markdown content of their respective phases.

## 1. Data Model (`ConversationModels.swift`)
- [ ] Add `formatVectorResultsToMarkdown()` extension function to `Message`.
- [ ] Add `formatWebResultsToMarkdown()` extension function to `Message`.

## 2. Phase Card (`PhaseCard.swift`)
- [ ] Define `baseContent` using `message.getPhaseContent(phase)`.
- [ ] Define `combinedMarkdown` starting with `baseContent`.
- [ ] Conditionally append `message.formatVectorResultsToMarkdown()` to `combinedMarkdown` if `phase == .experienceVectors` and results exist.
- [ ] Conditionally append `message.formatWebResultsToMarkdown()` to `combinedMarkdown` if `phase == .experienceWeb` and results exist.
- [ ] Update `hasDisplayableContent` check to use `!combinedMarkdown.isEmpty`.
- [ ] Modify `PaginatedMarkdownView` instantiation:
    - [ ] Pass `combinedMarkdown` to the `markdownText` parameter.
    - [ ] Remove the `searchResults` parameter.
- [ ] Remove the `@ObservedObject var viewModel: PostchainViewModel` property if it's no longer needed after removing `SearchResultListView` dependency (Check if `PhaseCardContextMenu` or other parts still use it).
- [ ] Update `#Preview` block:
    - [ ] Remove `viewModel` instantiation and passing if removed from `PhaseCard`.
    - [ ] Ensure preview messages correctly show appended Markdown.

## 3. Paginated Markdown View (`PaginatedMarkdownView.swift`)
- [ ] Remove the `searchResults: [UnifiedSearchResult]` property.
- [ ] Remove the `PageContent` enum.
- [ ] Change `@State private var pages: [PageContent]` to `@State private var pages: [String]`.
- [ ] Remove the `onChange(of: searchResults)` modifier.
- [ ] Remove the `pageContentView()` function.
- [ ] Modify the `body`'s `ZStack` content:
    - [ ] Directly call `markdownPageView(pages[currentPage])` if `pages.indices.contains(currentPage)`.
    - [ ] Add placeholder/loading logic if pages aren't ready but `markdownText` exists.
- [ ] Remove the `resultsPageView()` function.
- [ ] Remove the `resultCardView()` function.
- [ ] Simplify `paginateContent(size:)`:
    - [ ] Remove `resultPages` calculation (`chunkResults`).
    - [ ] Set `pages` directly from `splitMarkdownIntoPages(markdownText, size: size)`.
    - [ ] Ensure `totalPages` is calculated correctly based on `pages.count`.
    - [ ] Keep the `currentPage` boundary adjustment logic.
- [ ] Refine `splitMarkdownIntoPages` height calculation (subtract padding and controls height).
- [ ] Remove the `chunkResults()` function.
- [ ] Simplify `extractCurrentPageText()` to only handle the markdown page string.
- [ ] Add pagination controls (`HStack` with buttons and page indicator) directly within the main `VStack`.
- [ ] Update `onLongPressGesture` to pass the correct text/range from the markdown page to `TextSelectionManager`.

## 4. Remove Search Result List View
- [ ] Delete the file `Choir/Views/SearchResultListView.swift`.
    - This implicitly removes `UnifiedSearchResult`, `VectorResultCard`, `WebResultCard`, and `PaginationControls`.

## 5. Postchain View Model (`PostchainViewModel.swift`)
- [ ] Verify `updatePhaseData` correctly populates `message.vectorSearchResults` and `message.webSearchResults` (Seems correct).
- [ ] (Optional) Consider removing `vectorResults`, `webResults`, `vectorSources`, `webSearchSources` computed properties if confirmed unused elsewhere. (Defer for now).

## 6. Postchain View (`PostchainView.swift`)
- [ ] Remove the `calculateAccurateTotalPages` function.
- [ ] Simplify `handlePageTap(direction:size:)`:
    - [ ] Remove the call to `calculateAccurateTotalPages`.
    - [ ] Remove the `totalPages` variable.
    - [ ] Modify the logic to rely on `PaginatedMarkdownView`'s internal state/callbacks for page changes within a phase. The tap overlay should primarily trigger *phase* switching when at the boundary (page 0 for previous, last page for next - though this boundary check is now handled by `PaginatedMarkdownView`'s callbacks).
    - [ ] Refine tap logic: Should the tap overlay *simulate* the internal button press in `PaginatedMarkdownView` or just handle phase switching? The plan suggests simplifying to just phase switching via `switchToPhase`.
- [ ] Review `switchToPhase(direction:)`: Ensure page reset logic for the *new* phase is correct (Plan suggests simplifying to always reset to page 0).

## 7. Testing
- [ ] Test phases *without* search results display correctly.
- [ ] Test `experienceVectors` phase displays appended vector results in Markdown.
- [ ] Test `experienceWeb` phase displays appended web results in Markdown.
- [ ] Test pagination within phases containing only text.
- [ ] Test pagination within phases containing text + appended results.
- [ ] Test navigation between phases (swipe and tap).
- [ ] Test page reset logic when switching phases.
- [ ] Test long-press text selection on markdown content.
- [ ] Test link tapping within markdown.
- [ ] Test loading states.
- [ ] Test empty states.
- [ ] Verify `#Preview` blocks work correctly for `PhaseCard` and `PostchainView`.
