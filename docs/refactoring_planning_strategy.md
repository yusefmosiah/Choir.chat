# PostChain UI Redesign: Carbon Fiber Kintsugi Strategy

VERSION postchain_redesign: 3.1 (iOS 17.6, Carbon Fiber Kintsugi)

## Overview

- **Core Vision**: Full-screen, page-based PostChain experience with vertical, TikTok-style paging. Long content scrolls inside a page; elastic page turning at top/bottom. Visual language is carbon fiber kintsugi: pressed/forged and woven carbon textures with gold, rose gold, and platinum accents.
- **Platform**: iOS 17.6, SwiftUI-first. iPhone-first; runs on iPad but no iPad-specific layouts until iPhone is finalized.
- **Scope Update**: Remove audio/TTS entirely for this iteration.
- **Timeline**: 8–12 focused hours for Phase 1 visuals and navigation, followed by polish passes.

## UX Structure

- **Pages (in order)**:
  1) Prompt (editable inline; replaces input bar)
  2) Action (fast response)
  3) Experience (vectors + web) with collapsible sections: Sources and Experience Rewards
  4) Intention + Observation + Understanding with collapsible sections
  5) Yield (final response), with citations shown as footnotes (to minimize visual disruption)
- **Population**: Each page streams content as it arrives. A page becomes “complete” when all its contributing phases for that page report `status == complete`.
- **Auto-advance**: Auto-scroll forward to the next page only when that page is complete and the user has not interacted for ≥ 3s. Never auto-scroll backward. If user is ahead of content, show a small “New content ready” pill to jump.
- **Missing Phases**: Skip pages whose content is absent; no empty placeholders.
- **Prompt Editing**: The input bar is removed. Users edit the prompt directly on the Prompt page. Additionally, users can always scroll beyond the last rendered page to access a dedicated “New Prompt” page for composing a new prompt (starts a new message/thread entry). Edits create a new message to preserve history (no destructive mutation).

## Navigation & Gestures

- **Vertical Pager**: Custom vertical pager with elastic, snap-to-page behavior. Each page contains its own `ScrollView` for long content.
- **Nested Scroll Handoff**: When a page’s inner scroll reaches its top/bottom, over-scroll can trigger page turns.
  - Defaults: over-scroll ≥ 80pt or vertical fling velocity ≥ 600pt/s triggers a page change. These are tunable constants; may be set to “disabled” to require explicit page drags ≥ 30% of height.
- **Haptics**: Light impact on page snap, soft boundary haptic at first/last page. Respect Reduced Motion.
- **Horizontal Gestures**: Disabled for now (reserved for potential thread switching later).
- **Chrome & Indicators**:
  - Chrome: Chrome-less by default. Top-left Back and top-right Overflow (share/more) fade in on tap.
  - Page Indicator: Optional. Default OFF. If enabled, show minimal numeric “current/total” at right edge with subtle metallic accent.
- **New Prompt Access**: Scrolling beyond the last rendered page reveals a full-screen “New Prompt” page for input (replaces any bottom input bar UX).

## Content & Sections

- **Experience Page**:
  - Sections: Sources (vectors + web) and Experience Rewards (collapsible). Sources can include expandable details.
  - Rewards: Shown as a collapsible metallic card. First reveal uses subtle shimmer; no particles. Respect Reduced Motion.
- **IOU Page (Intention/Observation/Understanding)**:
  - Three collapsible sections. Default collapsed; expand with smooth spring. Streaming inserts new content within its section.
- **Yield Page**:
  - Final response with citations rendered as footnotes, placed after the main text to avoid disrupting flow.
- **Long Content**: Comfortable line lengths; code blocks styled and height-capped; tables horizontally scroll within the page; images tap to zoom.
- **Streaming Visuals**: Progressive paragraph reveals (no typewriter). Subtle metallic accent lines are acceptable; avoid heavy shimmer.
- **Persistent Scroll Memory**: Persist per-page scroll offset per message and restore when returning.
- **Cards vs Pages**: Pages are full-screen. “Cards” are no longer page containers; they are used only within multi-phase pages (Experience, IOU) to differentiate collapsible sections. Action and Yield pages display pure, borderless full-screen text with no card/border treatment.

## Visual System

- **Textures**: Pressed/forged and woven carbon only. Use pre-rendered, raster assets for performance; optional subtle procedural overlay for depth.
- **Metals**: Gold, rose gold, platinum. Prefer gradient metallics with gentle highlights; limit shimmer to rewards/accents.
- **Dark Theme**: Dark-only for v1; target WCAG AA contrast. Light theme later.

### Design Tokens (initial)

- **Colors**:
  - `carbon.base`: #0B0B0B
  - `carbon.depth`: #060606
  - `text.primary`: #F2F2F2
  - `text.secondary`: #A6A6A6
  - `kintsugi.gold[0..1]`: #E6C200 → #FFDC73
  - `kintsugi.rose[0..1]`: #E5B1B1 → #FFC2B2
  - `kintsugi.platinum[0..1]`: #D8D8D8 → #F0F0F0
- **Gradients**:
  - `metal.gold`: linear(topLeading→bottomTrailing, stops: gold[0], gold[1])
  - `metal.rose`: linear(topLeading→bottomTrailing, stops: rose[0], rose[1])
  - `metal.platinum`: linear(topLeading→bottomTrailing, stops: platinum[0], platinum[1])
- **Radii**: xs 8, s 12, m 16, l 20, xl 28
- **Spacing**: 4, 8, 12, 16, 20, 24, 32
- **Shadows**: base (black 0.6, r: 12, y: 6), lift (black 0.4, r: 20, y: 10)
- **Motion**:
  - `spring.page`: response 0.4, damping 0.8
  - `spring.expand`: response 0.35, damping 0.85
  - Durations: snap 0.22s, fade 0.18s

## Performance Budget

- **Targets**: 60 FPS on iPhone 12+; <16ms frame time. Memory stable with textures cached.
- **Animation Budget**: Max 2 live animated layers per screen. Prefer opacity/offset; avoid scale on large layers when possible.
- **Textures**: Pre-render pressed/forged/woven carbon at app start; reuse across views. Keep total raster memory for textures < 12 MB.
- **Shaders**: If used, keep to low-cost overlays; no heavy noise/particles.

## Accessibility

- **VoiceOver**: Order by page; rotor to navigate sections within page. Clear labels for collapsibles and footnotes.
- **Dynamic Type**: Support up to Extra Large; reflow content and maintain paging thresholds.
- **Reduced Motion**: Disable shimmer and large-scale transforms; use metallic gradients and subtle opacity fades.
- **Color**: Do not rely solely on color to denote metals/status; incorporate icons or patterns where needed.

## Data & State Integration

- **Adapter**: Introduce `PostChainPage` as a thin adapter that maps existing `Phase`-based streaming events into page models.
- **Completeness**: A page is complete when all of its mapped phases emit `status == complete`.
- **Streaming Updates**: Append content progressively (paragraph blocks) rather than character-by-character.
- **Persistence**: Store per-message, per-page scroll offset. Restore on re-entry.
- **Errors**: Show inline banners within the relevant page; do not add a separate error page.

## Rewards Model

- **Experience Rewards**: Collapsible section on the Experience page. Metallic card; first reveal shimmer only; respects Reduced Motion.
- **Yield Citation Rewards**: Displayed as footnotes within the Yield page. Clarify that rewards are issued to cited prior authors, not the current prompt author.

## Rollout & Analytics

- **Feature Flag**: Toggle “New PostChain UI”. Fallback to current carousel.
- **Analytics**: Log page dwell time, successful page snaps, auto-advance usage, early exits, and collapsible toggles (anonymized/local).

## Risks & Mitigations

- **Gesture Conflicts**: Nested scroll handoff may feel sticky. Mitigate with tunable thresholds and clear haptics.
- **Performance**: Textures and shimmer risk dropped frames. Use raster caches, limit animated layers, and honor Reduced Motion.
- **Streaming Jitter**: Rapid updates can cause layout shifts. Buffer by paragraph and coalesce updates on a short debounce.
- **Dynamic Type Expansion**: Large text can blow layout. Cap line length, allow vertical growth, maintain snap bounds.

## Success Criteria

- **Interaction**: Page snap latency ≤ 16ms budget; no visible stutter on iPhone 12+.
- **Gestures**: Reliable nested handoff with default thresholds; 0 missed snaps in manual QA across 30 swipes.
- **Streaming**: Content updates append smoothly without jumping; auto-advance respects user intent.
- **Accessibility**: VoiceOver navigable by page/section; Reduced Motion honored; contrast AA.
- **Visual**: Carbon fiber and metals feel premium without overpowering readability.

## Implementation Plan

### Phase 1: Pager + Visual Foundation (Hours 1–3)

- Build `CarbonFiberTexture` (pressed/forged/woven) as reusable backgrounds using raster assets with optional subtle overlay.
- Create `KintsugiAccent` (gold/rose/platinum gradients) for borders, dividers, and highlights.
- Implement `VerticalPostChainPager` with snap-to-page, haptics, and nested scroll handoff (defaults: 80pt, 600pt/s; flag to disable).
- Define `PostChainPage` adapter mapping from existing `Phase` into page models and completeness rules.
- Scaffold pages: Prompt (editable), Action (borderless), Experience (collapsible sections), IOU (collapsible sections), Yield (borderless with footnotes). Integrate per-page `ScrollView` and persistent scroll memory. Add “New Prompt” terminal page revealed on overscroll past the last page.

### Phase 1a: Hard Refactor Cleanup

- Remove legacy pagination and card abstractions:
  - Delete `MarkdownPaginator`, `PaginationUtils`, and `PaginationCacheManager` usage; migrate any pagination-dependent code to the new pager.
  - Delete `PhaseCard` and `PhaseCardContextMenu`; replace with collapsible section components used only inside Experience/IOU pages.
  - Update `PostchainView` and any callers to use `VerticalPostChainPager` and full-screen page components. Remove the bottom input bar.

### Phase 2: Sections, Rewards, Streaming Polish (Hours 4–6)

- Experience page: Collapsible Sources + Experience Rewards section; settled metallic card; first-reveal shimmer with Reduced Motion fallback.
- IOU page: Collapsible sections with spring expand/collapse and streaming-friendly inserts.
- Yield page: Final response with footnote citations; clear “issued to cited authors” copy for citation rewards.
- Optional page indicator (OFF by default) as numeric “current/total” at right edge.
- Auto-advance integration based on completeness + 3s idle; “New content ready” jump pill when user is ahead.
- Prompt editing polish: Inline editing ergonomics and confirmation flow; ensure edits create a new message entry and preserve history.

### Phase 3: Perf, Accessibility, Rollout (Hours 7–12)

- Performance pass: texture caching, animation layer audit, shader removal if needed.
- Accessibility pass: VoiceOver labels, rotor ordering, Dynamic Type validation, Reduced Motion audit.
- Feature flag + fallback wiring; basic analytics for dwell and snaps.
- Token finalization: color, gradients, radii, spacing, shadows, motion; document usage.

## Notes

- Audio/TTS removed for this iteration; defer until after iPhone UI stabilization.
- iPad runs the same UI for now; no split/dual-pane variants until the iPhone experience is finalized.
