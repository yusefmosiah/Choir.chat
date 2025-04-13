# Choir Performance Optimization Checklist

## Performance Issues Identified
- Drag gesture animation in PostchainView causing CPU spikes
- UI freezes with long text input
- High CPU usage during scrolling messages
- Expensive text measurement and pagination calculations

## Optimization Checklist

### Drag Gesture Performance (PostchainView)
- [ ] **Critical**: Remove animation from `.onChanged` handler, only animate on `.onEnded`
- [ ] Apply `.drawingGroup()` selectively to PhaseCard instances
- [ ] Optimize offset/opacity calculations to use simpler arithmetic
- [ ] Cache card positions where possible, reduce recalculations
- [ ] Refactor to use transaction.disablesAnimations during drag

### Text Input Optimization (ThreadInputBar)
- [ ] Implement multiline TextEditor instead of TextField for better long text handling
- [ ] Add character counting with visual feedback for very long inputs
- [ ] Implement progressive rendering for extremely long inputs
- [ ] Add input throttling for live updates during typing
- [ ] Optimize text storage for large inputs

### Component Loading & Rendering
- [ ] Implement lazy loading for PostchainView within MessageRow
- [ ] Create lightweight placeholders for off-screen content
- [ ] Fix memory leaks from heavy view instances
- [ ] Remove unnecessary print/debug statements in critical rendering paths
- [ ] Reduce view hierarchy complexity where possible

### Text Measurement & Pagination
- [ ] Cache pagination results to avoid recalculation
- [ ] Move text measurement to background threads using async/Task
- [ ] Implement virtual rendering (only render visible content)
- [ ] Optimize or throttle geometry change handling
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

## Impact Measurement
Use the following metrics to evaluate each optimization:
- CPU usage during drag/scroll operations
- Memory usage trend during long sessions
- Time to render complex markdown content
- Input lag when typing long prompts
- Frame rate during animations