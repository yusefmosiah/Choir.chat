# Refactor Plan: Horizontal Carousel → Vertical Phases → Theming → UX

Audience: AI coding agent familiar with SwiftUI and this repository.
Scope: Replace the horizontal, card-based phase carousel with vertical, phase-grouped pages (Stage 1), then apply Carbon Fiber Kintsugi theming (Stage 2), followed by iterative UX improvements (Stage 3).

Codebase anchors referenced below exist in this repo:
- Views: `Choir/Views/PostchainView.swift`, `Choir/Views/PaginatedMarkdownView.swift`, `Choir/Views/PhaseCard.swift`, `Choir/Views/GlassPageControl.swift`, `Choir/Views/MessageRow.swift`
- Models: `Choir/Models/ConversationModels.swift` (`Phase`, `Message`)
- ViewModel: `Choir/ViewModels/PostchainViewModel.swift`
- Utils: `Choir/Utils/PaginationCacheManager.swift`

## Goals & Non‑Goals

- Goal: Ship Stage 1 by preserving current content rendering/behavior while changing navigation from horizontal carousel to vertical, phase-grouped pages.
- Goal: Keep streaming, deep links, and pagination performance parity in Stage 1.
- Non‑Goal (Stage 1): No carbon/kintsugi visuals, no major layout restyle, no prompt-edit page.
- Non‑Goal: Do not change backend or API contracts.

## Stage 1 — Vertical Phase Pages (ship first)

Outcome: Replace the horizontal carousel of per‑phase cards with a vertically scrolling stack of pages, where certain phases are grouped. Keep existing markdown rendering and data flow intact.

Phase grouping for Stage 1:
- Page A: `action`
- Page B: `experience` (merge content from `experienceVectors` + `experienceWeb`)
- Page C: `iou` (merge `intention`, `observation`, `understanding`)
- Page D: `yield`

Behavioral rules:
- Only render a page if it has any content or the app is currently streaming that phase.
- Within each page, long content scrolls vertically in a `ScrollView`. No snap paging in Stage 1.
- Preserve deep-link handling and tap/long‑press behavior from `PaginatedMarkdownView`.
- Preserve existing pagination performance via `PaginationCacheManager` where helpful for very long markdown.

### Stage 1: Implementation Steps

1) Add feature flag
- Create `UseVerticalPhasesUI` (Bool) in `UserDefaults` with helper:
  - File: `Choir/Utils/FeatureFlags.swift` (new)
  - API:
    - `FeatureFlags.useVerticalPhasesUI` (computed Bool with default `false`)
    - `FeatureFlags.toggleVerticalPhasesUI()`
- Optional: expose a toggle in `SettingsView` to switch between UIs at runtime.

2) Introduce vertical pages container
- File: `Choir/Views/VerticalPostchainView.swift` (new)
- Purpose: Replacement for `PostchainView` when flag is ON.
- Structure:
  - `enum PhasePage: CaseIterable { case action, experience, iou, yield }`
  - Map `Phase` → `PhasePage` with helpers:
    - `func hasContent(page: PhasePage, message: Message) -> Bool` combines existing `message.getPhaseContent(_:)`, `vectorSearchResults`, `webSearchResults`, and `message.isStreaming`.
  - Build a `VStack`/`ScrollViewReader` containing 0–4 pages in order; each page is a full‑width section with its own content view and per‑page vertical scrolling.
  - Respect Dynamic Type and Reduced Motion (no animations required in Stage 1).

3) Page views
- Files (new):
  - `Choir/Views/Pages/ActionPageView.swift`
  - `Choir/Views/Pages/ExperiencePageView.swift`
  - `Choir/Views/Pages/IOUPageView.swift`
  - `Choir/Views/Pages/YieldPageView.swift`
- Content guidelines:
  - Use existing `PaginatedMarkdownView` for textual sections where applicable to keep rendering parity. Pass `currentMessage: Message` so deep links work.
  - Experience page: concatenate text from `experienceVectors` + `experienceWeb` and append formatted sources using existing helpers `message.formatVectorResultsToMarkdown()` and `message.formatWebResultsToMarkdown()`. No collapsibles yet.
  - IOU page: concatenate `intention`, `observation`, `understanding` markdown in that order with clear H2 headings between them.
  - Yield page: render yield markdown. Keep citations inline as they exist today (footnote restyle is Stage 3).
  - All pages should tolerate empty sections and simply omit them.

4) Wire up the new view
- Update `Choir/Views/MessageRow.swift`:
  - When `FeatureFlags.useVerticalPhasesUI == true` and `!message.isUser`, render `VerticalPostchainView(message:isProcessing:viewModel: ...)` instead of `PostchainView`.
  - Keep lazy load behavior intact (placeholder → load full view) to preserve perf.
- Do not delete `PostchainView`/`PhaseCard`/`GlassPageControl` in Stage 1; they remain the fallback when flag OFF.

5) Data flow and streaming
- Reuse existing `Message` and `PostchainViewModel` without signature changes.
- Ensure `VerticalPostchainView` listens for `message.objectWillChange` and `message.phaseResults` changes similarly to `PostchainView` so pages refresh during streaming.
- No auto‑advance in Stage 1; users scroll manually between pages.

6) Pagination/perf
- For very long markdown, reuse `PaginationCacheManager` by invoking `getPaginatedContentSync` to split text per page’s available height and render via `PaginatedMarkdownView` page-by-page, or fallback to a single `PaginatedMarkdownView` if unnecessary. Keep this minimal to avoid churn; correctness > micro‑perf.

7) Telemetry and logging
- Add lightweight debug logs for page composition (which pages render for a message) and page heights; gate logs behind `#if DEBUG`.
- No analytics schema change in Stage 1.

8) Acceptance criteria (Stage 1)
- Horizontal carousel is not used when flag is ON; vertical pages render instead.
- All existing content renders with parity, including vector/web deep links and long‑press selection.
- Streaming updates appear on the correct page without flicker or layout jumps.
- Dynamic Type up to Extra Large preserves readability and scrollability.
- No crashes across iPhone 12+; performance roughly on par with current view.

### Stage 1: Files to Add/Modify

- Add: `Choir/Utils/FeatureFlags.swift`
- Add: `Choir/Views/VerticalPostchainView.swift`
- Add: `Choir/Views/Pages/ActionPageView.swift`
- Add: `Choir/Views/Pages/ExperiencePageView.swift`
- Add: `Choir/Views/Pages/IOUPageView.swift`
- Add: `Choir/Views/Pages/YieldPageView.swift`
- Modify: `Choir/Views/MessageRow.swift` to conditionally use vertical view
- Optional: `Choir/Views/SettingsView.swift` to expose a toggle

### Stage 1: Code Sketches

Feature flags (new file):
```
// Choir/Utils/FeatureFlags.swift
import Foundation

enum FeatureFlags {
    private static let key = "UseVerticalPhasesUI"
    static var useVerticalPhasesUI: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
    static func toggleVerticalPhasesUI() { useVerticalPhasesUI.toggle() }
}
```

Map pages and render (skeleton):
```
// Choir/Views/VerticalPostchainView.swift
import SwiftUI

enum PhasePage: CaseIterable { case action, experience, iou, yield }

struct VerticalPostchainView: View {
  @ObservedObject var message: Message
  let isProcessing: Bool
  @ObservedObject var viewModel: PostchainViewModel

  var pages: [PhasePage] {
    PhasePage.allCases.filter { hasContent($0) }
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView { LazyVStack(spacing: 24) {
        ForEach(pages.indices, id: \._self) { i in
          switch pages[i] {
          case .action: ActionPageView(message: message)
          case .experience: ExperiencePageView(message: message)
          case .iou: IOUPageView(message: message)
          case .yield: YieldPageView(message: message)
          }
        }
      }.padding(.horizontal) }
    }
  }

  private func hasContent(_ page: PhasePage) -> Bool {
    switch page {
    case .action:
      return !message.getPhaseContent(.action).isEmpty || message.isStreaming
    case .experience:
      return !message.getPhaseContent(.experienceVectors).isEmpty ||
             !message.getPhaseContent(.experienceWeb).isEmpty ||
             !message.vectorSearchResults.isEmpty ||
             !message.webSearchResults.isEmpty || message.isStreaming
    case .iou:
      return !message.getPhaseContent(.intention).isEmpty ||
             !message.getPhaseContent(.observation).isEmpty ||
             !message.getPhaseContent(.understanding).isEmpty || message.isStreaming
    case .yield:
      return !message.getPhaseContent(.yield).isEmpty || message.isStreaming
    }
  }
}
```

Message row selection (diff intent):
```
// In Choir/Views/MessageRow.swift body
if shouldLoadFullContent {
  if FeatureFlags.useVerticalPhasesUI {
    VerticalPostchainView(
      message: message,
      isProcessing: isProcessing,
      viewModel: viewModel
    )
  } else {
    PostchainView(
      message: message,
      isProcessing: isProcessing,
      viewModel: viewModel,
      localThreadIDs: [],
      forceShowAllPhases: true,
      coordinator: viewModel.coordinator as? PostchainCoordinatorImpl,
      viewId: message.id
    )
  }
}
```

Page views can wrap current markdown renderer:
```
// Choir/Views/Pages/ActionPageView.swift
struct ActionPageView: View {
  @ObservedObject var message: Message
  var body: some View {
    let text = message.getPhaseContent(.action)
    PaginatedMarkdownView(pageContent: text, currentMessage: message)
  }
}
```

## Stage 2 — Carbon Fiber Kintsugi Theming (after Stage 1 deploy)

Outcome: Apply the new visual language without structural changes.

Design tokens (SwiftUI):
- File: `Choir/Utils/Theme/Tokens.swift` (new)
- Provide colors, gradients, spacing, radii, shadows, motion constants. Dark theme only.

Assets:
- Add pre‑rendered raster textures for pressed/forged/woven carbon into `Assets.xcassets/Carbon/*.imageset`.
- Do not exceed ~12MB total for texture assets.

Application:
- Add background decorators (textures) and metallic accents to the new vertical page views and section dividers.
- Keep content contrast AA. Respect Reduced Motion; avoid shimmer except optional subtle reward highlight later.
- Keep old horizontal UI unstyled (fallback only).

Acceptance criteria (Stage 2):
- Theming behind a separate `FeatureFlags.useKintsugiTheme` (default OFF) or piggyback on Stage 1 flag as agreed.
- No functional regressions; text remains legible; A11y focus and Dynamic Type remain good.

## Stage 3 — Iterative UX Tweaks

Candidate improvements (ship in small PRs):
- Collapsible sections in Experience (Sources, Rewards) and IOU with smooth spring.
- Auto‑advance to next page when a page’s contributing phases complete and user is idle for ≥3s.
- Page index indicator (optional), keyboard shortcuts, sticky TOC for long pages.
- Yield citations as footnotes at bottom; link tap scrolls to footnote.
- Haptics on significant interactions; Reduced Motion safe.

Acceptance criteria (Stage 3):
- Each tweak has a measurable usability or clarity benefit; no perf regressions.

## Risks & Safeguards

- Risk: Streaming updates causing layout jumps.
  - Mitigation: Recompute page visibility on main thread; avoid transient empty headings; coalesce updates with short debounce only if needed.
- Risk: Deep link handling divergence between views.
  - Mitigation: Centralize link handling inside `PaginatedMarkdownView` (already present); reuse everywhere.
- Safeguards: Feature flags for Stage 1 and Stage 2; easy rollback by flipping flags.

## Test & QA Checklist

- Content parity across phases vs. current `PostchainView`.
- Vector and web deep links open sheets and external URLs correctly.
- Large markdown: no truncation; pagination still works; scrolling is smooth.
- Dynamic Type XL: text reflows without clipped content.
- VoiceOver: page sections announced logically; links actionable.
- iPhone 12+ devices: no crashes, acceptable scroll performance.

## Deployment Plan

- Stage 1: Land behind `UseVerticalPhasesUI` flag. Canary by enabling flag locally; then default ON in TestFlight; flip ON in prod after validation.
- Stage 2: Land theming behind separate flag; canary → roll out.
- Stage 3: Ship small, reversible UX enhancements behind guarded toggles where prudent.

## Agent Notes

- Keep diffs focused. Do not remove old carousel code in Stage 1.
- Reuse existing models and streaming pathways; avoid API or ViewModel signature changes.
- Prefer small PRs: add files → wire flag → verify parity → iterate.

