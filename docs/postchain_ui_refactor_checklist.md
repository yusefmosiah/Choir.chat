# PostChain UI Refactor Checklist: Full-Screen Vertical Page Navigation

## Overview
Complete architectural change from message-list-with-cards to full-screen-page-book navigation.

**Goal**: Replace vertical message list with vertical page navigation where:
- User message = Full-screen page
- Each AI phase = Full-screen page  
- Experience page = Collapsible sections (vectors + web)
- IOU page = Collapsible sections (intention + observation + understanding)
- Vertical swiping between pages (no horizontal scrolling)

## Phase 1: Remove Dead Code (Hard Refactor)

### ❌ Components to Remove Completely
- [ ] `PostchainView.swift` - Old horizontal scrolling implementation
- [ ] `PhaseCard.swift` - Individual phase cards no longer needed
- [ ] `GlassPageControl.swift` - Tab bar component for cards
- [ ] `ThreadMessageList.swift` - Alternative message list component
- [ ] Any horizontal scrolling logic in `VerticalPostchainView.swift`

### ❌ Code to Remove from Existing Files
- [ ] Remove horizontal scrolling logic from `VerticalPostchainView`
- [ ] Remove tab bar/page control from existing page views
- [ ] Remove card-based styling and layout code
- [ ] Remove message-row-based architecture from `ChoirThreadDetailView`

## Phase 2: Create New Core Components

### ✅ New Components to Create

#### 2.1 User Message Page
- [ ] `UserMessagePageView.swift` - Full-screen user message display
  - [ ] Large, readable text display
  - [ ] Timestamp and metadata
  - [ ] Consistent styling with AI pages
  - [ ] Proper scrolling for long messages

#### 2.2 Conversation Page Container  
- [ ] `ConversationPageView.swift` - Main container replacing `ChoirThreadDetailView`
  - [ ] Flattens all messages into sequential pages
  - [ ] Vertical page navigation logic
  - [ ] Page transition animations
  - [ ] Current page tracking
  - [ ] Handles user messages + AI phase pages

#### 2.3 Collapsible Section Components
- [ ] `CollapsibleSection.swift` - Reusable expandable/contractable section
  - [ ] Smooth expand/collapse animations
  - [ ] Header with expand/collapse indicator
  - [ ] Content area that shows/hides
  - [ ] State persistence across page navigation

#### 2.4 Page Navigation Controller
- [ ] `PageNavigationController.swift` - Handles vertical page swiping
  - [ ] Vertical swipe gesture recognition
  - [ ] Page transition animations
  - [ ] Elastic scrolling with snap-back
  - [ ] Disable horizontal scrolling completely
  - [ ] Page boundary detection

## Phase 3: Modify Existing Page Views

### 🔄 Update Experience Page
- [ ] Modify `ExperiencePageView.swift`:
  - [ ] Add collapsible sections for vectors and web results
  - [ ] Remove any card-based styling
  - [ ] Ensure full-screen layout
  - [ ] Add section headers with expand/collapse controls

### 🔄 Update IOU Page  
- [ ] Modify `IOUPageView.swift`:
  - [ ] Add collapsible sections for intention, observation, understanding
  - [ ] Remove any card-based styling  
  - [ ] Ensure full-screen layout
  - [ ] Add section headers with expand/collapse controls

### 🔄 Update Action and Yield Pages
- [ ] Modify `ActionPageView.swift`:
  - [ ] Remove any card-based styling
  - [ ] Ensure full-screen layout
  - [ ] Remove page controls/tabs

- [ ] Modify `YieldPageView.swift`:
  - [ ] Remove any card-based styling
  - [ ] Ensure full-screen layout
  - [ ] Remove page controls/tabs

## Phase 4: Replace Conversation Architecture

### 🔄 Update Thread Detail View
- [ ] Completely replace `ChoirThreadDetailView.swift`:
  - [ ] Remove `ScrollView` with `LazyVStack` of `MessageRow`
  - [ ] Replace with `ConversationPageView`
  - [ ] Keep toolbar and navigation elements
  - [ ] Keep input bar at bottom
  - [ ] Update state management for page-based navigation

### ❌ Remove Message Row Architecture
- [ ] Remove or deprecate `MessageRow.swift`
- [ ] Remove lazy loading logic for individual messages
- [ ] Remove message-based view state management

## Phase 5: Update Navigation and State Management

### 🔄 Page State Management
- [ ] Update `Message` model if needed for page navigation
- [ ] Update `PostchainViewModel` for page-based state
- [ ] Add conversation-level page tracking
- [ ] Handle page navigation state persistence

### 🔄 Input and Processing
- [ ] Ensure `ThreadInputBar` works with new page architecture
- [ ] Update message sending to work with page navigation
- [ ] Handle streaming updates in page-based view
- [ ] Update processing indicators for page context

## Phase 6: Navigation Gestures and Animations

### ✅ Vertical Page Navigation
- [ ] Implement vertical swipe gestures (up/down)
- [ ] Disable horizontal scrolling completely
- [ ] Add smooth page transition animations
- [ ] Implement elastic scrolling with thresholds
- [ ] Add haptic feedback for page transitions

### ✅ Page Indicators
- [ ] Add subtle page indicators (dots or progress)
- [ ] Show current page position in conversation
- [ ] Handle dynamic page count as conversation grows

## Phase 7: Testing and Polish

### 🧪 Core Functionality Testing
- [ ] Test conversation flow with multiple exchanges
- [ ] Test page navigation in both directions
- [ ] Test collapsible sections expand/collapse
- [ ] Test streaming updates in page context
- [ ] Test input bar functionality

### 🧪 Edge Cases
- [ ] Test with very long user messages
- [ ] Test with missing AI phases
- [ ] Test with streaming interruptions
- [ ] Test page navigation during streaming
- [ ] Test memory management with many pages

### 🎨 Polish and Performance
- [ ] Optimize page transition animations
- [ ] Ensure smooth scrolling performance
- [ ] Add loading states for page content
- [ ] Optimize memory usage for large conversations
- [ ] Add accessibility support for page navigation

## Phase 8: Cleanup and Documentation

### 🧹 Final Cleanup
- [ ] Remove all unused imports
- [ ] Remove commented-out old code
- [ ] Update any remaining references to old components
- [ ] Clean up debug logging

### 📚 Documentation Updates
- [ ] Update component documentation
- [ ] Document new page navigation architecture
- [ ] Update any architectural diagrams
- [ ] Add usage examples for new components

## Success Criteria

✅ **Complete when:**
- [ ] Conversations display as full-screen pages with vertical navigation
- [ ] User messages and AI phases each take full screen
- [ ] Experience and IOU pages have working collapsible sections
- [ ] No horizontal scrolling anywhere in the interface
- [ ] Smooth vertical page transitions with proper gestures
- [ ] All old horizontal scrolling code removed
- [ ] Performance is smooth with large conversations

## Notes

- **This is a hard refactor** - we're completely replacing the conversation architecture
- **Remove dead code aggressively** - don't leave old components around
- **Test frequently** - this touches core conversation functionality
- **Maintain concurrency** - keep existing streaming and processing logic working
- **Focus on user experience** - smooth animations and responsive gestures are critical
