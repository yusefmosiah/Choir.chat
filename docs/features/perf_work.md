# Choir Performance Optimization Checklist

## Performance Issues Identified
- Drag gesture animation in PostchainView causing CPU spikes
- UI freezes with long text input
- High CPU usage during scrolling messages
- Expensive text measurement and pagination calculations

## Optimization Checklist

### Drag Gesture Performance (PostchainView)
- [x] **Critical**: Remove animation from `.onChanged` handler, only animate on `.onEnded`
- [x] Refactor to use transaction.disablesAnimations during drag
- [ ] Optimize offset/opacity calculations to use simpler arithmetic
- [ ] Cache card positions where possible, reduce recalculations
- [ ] Apply `.drawingGroup()` selectively to PhaseCard instances

### Text Input Optimization (ThreadInputBar)
- [x] Implement multiline TextEditor instead of TextField for better long text handling
- [x] Add character counting with visual feedback for very long inputs
- [ ] Implement progressive rendering for extremely long inputs
- [ ] Add input throttling for live updates during typing
- [ ] Optimize text storage for large inputs

### Component Loading & Rendering
- [x] Implement lazy loading for PostchainView within MessageRow
- [x] Create lightweight placeholders for off-screen content
- [ ] Fix memory leaks from heavy view instances
- [ ] Remove unnecessary print/debug statements in critical rendering paths
- [ ] Reduce view hierarchy complexity where possible

### Text Measurement & Pagination
- [x] Cache pagination results to avoid recalculation
- [x] Optimize or throttle geometry change handling (debounce)
- [x] Add `.drawingGroup()` to markdown views for GPU acceleration
- [ ] Move text measurement to background threads using async/Task
- [ ] Implement virtual rendering (only render visible content)
- [ ] Precalculate text layout for common screen dimensions

### General Optimization
- [ ] Profile with Instruments to identify additional bottlenecks
- [ ] Use more granular ObservableObject properties to limit redraw scope
- [ ] Implement better memory management for large text content
- [ ] Convert inefficient Observable patterns to more optimized property wrappers
- [ ] Use @ViewBuilder to conditionally render lighter view hierarchies

## Implementation Approach
1. Measure baseline performance with Instruments (Time Profiler, Core Animation, SwiftUI)
2. Implement one change at a time
3. Profile after each change to measure impact
4. Keep changes that improve performance measurably
5. Document findings for each optimization

## Changes Implemented

### 1. Optimized Drag Gesture (PostchainView)
- Removed animation from `.onChanged` handler, only animate on `.onEnded`
- Added `withTransaction { transaction.disablesAnimations = true }` to prevent implicit animations during drag
- Expected impact: Significantly reduced CPU usage during drag operations, smoother card dragging

### 2. Enhanced Text Input (ThreadInputBar)
- Replaced simple TextField with dynamic-height TextEditor
- Added character counting with visual warning for very long inputs
- Added automatic height adjustment based on content
- Expected impact: Better handling of long text inputs, visual feedback for users, prevents UI freezes

### 3. Lazy Loading for Message Rows
- Implemented lazy loading for PostchainView within MessageRow
- Added lightweight placeholder views shown initially
- Only load full PostchainView after component is visible
- Expected impact: Faster scrolling through message list, reduced memory usage, less CPU spikes

### 4. Optimized Pagination and Markdown Rendering
- Added caching for pagination results to avoid redundant calculations
- Implemented debouncing for size changes to reduce excessive pagination
- Added `.drawingGroup()` to markdown views for GPU acceleration
- Expected impact: Faster rendering of markdown content, reduced CPU usage during scrolling/resizing

## Impact Measurement
Use the following metrics to evaluate each optimization:
- CPU usage during drag/scroll operations
- Memory usage trend during long sessions
- Time to render complex markdown content
- Input lag when typing long prompts
- Frame rate during animations