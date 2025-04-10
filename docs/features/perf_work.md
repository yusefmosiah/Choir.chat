Okay, here's a practical, 80/20-focused guide and checklist to tackle those performance spikes, prioritizing the changes likely to give you the biggest wins fastest.

Core Philosophy: Profile, Target, Iterate

Profile First: Use Instruments (Time Profiler, SwiftUI, Allocations) before changing anything to confirm where the bottleneck actually is during the specific interaction (drag, scroll, tap). Don't guess.

Target High Impact: Focus on the checklist items marked "Highest Priority" first. These address the most common and severe performance issues in SwiftUI interactions.

Implement One Thing: Make one significant change at a time.

Profile Again: Measure the impact of that single change. Did CPU/memory improve? Did it break anything?

Keep or Revert: Keep changes that demonstrably improve performance without negative side effects. Revert changes that don't help or make things worse.

Repeat: Move to the next highest priority item.

Performance Optimization Checklist (80/20 Focus)

🎯 Target 1: Drag Gesture Spikes (PostchainView)

[x] (Highest Priority) Apply .drawingGroup() to PhaseCard:
### partially completed. we are putting the markdown in a drawing group, but not the messages

Why: Offloads complex rendering (gradients, shadows, text, subviews) of the moving cards to Metal, drastically reducing main thread CPU load during animation/drag. Often the single biggest win for complex animating views.

How: In PostchainView, inside the ForEach loop creating PhaseCards, add the modifier: .drawingGroup().

Check: Profile CPU during drag. Monitor memory in Instruments (Allocations) - .drawingGroup() uses more memory (bitmap cache). Ensure the memory cost is acceptable.

[ ] (High Priority) Optimize Card Offset/Opacity Calculation:

Why: These functions (calculateOffset, calculateOpacity) run for every card on every frame of the drag. They must be extremely fast.

How: Review the logic. Ensure no complex calculations, string processing, or unnecessary state lookups. Use simple arithmetic. Profile these functions specifically if drag is still slow after .drawingGroup().

Check: Profile CPU during drag using Time Profiler.

[ ] (Medium Priority) Ensure Minimal Work in .onChanged:

Why: Code inside .onChanged runs continuously during the drag. Anything beyond updating the essential drag state (dragOffset) adds overhead.

How: Verify that only dragOffset = value.translation.width (or similar minimal state) happens in .onChanged. Move any logic for predicting the end state or calculating the target index strictly into .onEnded.

Check: Review PostchainView's DragGesture.

🎯 Target 2: Scrolling Spikes (ThreadMessageList, MessageRow)

[ ] (Highest Priority) Lazy Load PostchainView within MessageRow:

Why: Rendering the entire complex PostchainView (with its own GeometryReader, PhaseCards, PaginatedMarkdownView, etc.) for every AI message as it scrolls into view is likely the biggest cause of scroll stutter.

How:

In MessageRow, replace the direct PostchainView(...) call with a simpler placeholder view (e.g., just the header, maybe a static preview of the first few lines of content).

Add an @State private var shouldLoadPostchain = false.

Use .onAppear on the placeholder view to set shouldLoadPostchain = true after a tiny delay (DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)) or immediately.

Conditionally show the real PostchainView only when shouldLoadPostchain is true.

Check: Profile CPU and observe smoothness during scrolling through AI messages.

[ ] (High Priority) Optimize/Cache PaginatedMarkdownView Pagination:

Why: Text measurement (TextMeasurer) and calculating page splits (paginateContent) can be CPU-intensive, especially if run repeatedly or for large text blocks when a MessageRow appears during scroll.

How:

In PaginatedMarkdownView, ensure paginateContent is only called when markdownText, searchResults, or availableSize meaningfully changes. Avoid calling it on minor geometry updates if the content is the same.

Add @State private var cachedPages: [PageContent]? to PaginatedMarkdownView.

In paginateContent, once pages are calculated, store them in cachedPages. Use the cache if the inputs haven't changed.

Advanced: Consider moving pagination logic into the Message model itself, calculating pages asynchronously when data arrives and storing the result there.

Check: Profile CPU during scrolling, focusing on time spent in paginateContent and TextMeasurer.

🎯 Target 3: Tapping Spikes (PostchainView, TextSelectionSheet)

[ ] (High Priority) Optimize Page Calculation on Tap:

Why: handlePageTap in PostchainView calls calculateAccurateTotalPages, which uses TextMeasurer. Doing this synchronously on the main thread during a tap can cause a noticeable hitch.

How: Cache the totalPages result. Calculate it once when the PhaseCard content/size is determined (perhaps in PaginatedMarkdownView's paginateContent) and pass it down or store it in the Message model's state (message.phaseTotalPages[phase]). Read the cached value in handlePageTap instead of recalculating.

Check: Profile CPU during rapid taps on the left/right edges of PostchainView.

[ ] (Medium Priority) Optimize TextSelectionSheet Presentation:

Why: Presenting the sheet involves rendering TextSelectionView and its TextViewWrapper. If TextMeasurer is used implicitly (e.g., to calculate initial scroll range) or if TextViewWrapper's makeUIView/updateUIView is slow, it can cause a delay.

How: Profile the presentation. Ensure TextViewWrapper.updateUIView does minimal work if the text hasn't changed. If range calculation is slow, consider doing it asynchronously.

Check: Profile CPU/responsiveness when tapping buttons that trigger TextSelectionManager.shared.showSheet(...).

🎯 Target 4: General Quick Wins

[ ] Remove Debug Prints:

Why: Excessive print() statements, especially within drag handlers or view updates, can significantly impact performance.

How: Search for and remove/comment out print statements in performance-critical areas like DragGesture handlers, calculateOffset/opacity, MessageRow.body, PaginatedMarkdownView.body, paginateContent.

Check: Observe general responsiveness and profile CPU.

[ ] Verify No Main Thread Blocking:

Why: Any synchronous I/O (file, keychain), heavy data parsing, or long computation on the main thread blocks the UI.

How: Review code called directly from view bodies or interaction handlers. Ensure ThreadPersistenceService.saveThread is always called asynchronously (looks like it is via Task.detached). Double-check any large JSON decoding or data processing. Use Instruments' Time Profiler and filter for the main thread, looking for long-running operations.

Check: Profile interactions, look for hangs or stutters.

[ ] Review ViewModel Updates:

Why: Frequent updates from the Coordinator to the ViewModel (updateState, updatePhaseData) trigger @Published changes. Ensure these don't cause unnecessarily broad UI refreshes in ChoirThreadDetailView or its children.

How: Use SwiftUI Instruments to see which views are re-rendering when the ViewModel changes. Consider if ChoirThreadDetailView could use more granular state or .equatable() on subviews if appropriate.

Check: Profile view updates using SwiftUI Instruments during background processing or after interactions complete.

Process Reminder:

Pick an unchecked item (start with Highest Priority).

Instruments: Profile the specific interaction before the change.

Implement the change.

Instruments: Profile the same interaction after the change.

Compare CPU, Memory, and View Updates. Is it better?

Keep or Revert. Check the box if kept.

Repeat.

By focusing on these high-impact areas first, you should be able to significantly improve the perceived performance and reduce those spikes much faster. Good luck!
