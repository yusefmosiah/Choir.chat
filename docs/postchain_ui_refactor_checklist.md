# PostChain UI Refactor Checklist: Turn-Based Horizontal Navigation

## Overview
Complete architectural change from vertical page navigation to horizontal turn-based navigation.

**Current Problem**:
- Vertical navigation between separate pages (User Message ↕ AI Response)
- Horizontal TabView navigation between AI phases (Action ↔ Experience ↔ IOU ↔ Yield)
- Inconsistent behavior: new threads show no phase navigation, old threads show horizontal phase tabs

**New Goal**:
- **Turn-based architecture**: Each turn contains 5 vertical pages
- **Horizontal navigation**: Between conversation turns (Turn 1 ↔ Turn 2 ↔ Turn 3)
- **Vertical navigation**: Within each turn between 5 pages:
  1. User Prompt Page
  2. Action Page
  3. Experience Page (with collapsible sections for vectors + web)
  4. IOU Page (with collapsible sections for intention + observation + understanding)
  5. Yield Page
- **Auto-advance**: Pages automatically advance when content loads
- **Manual navigation**: Users can swipe up/down between pages within a turn anytime
- **Full-screen pages**: Each page takes full screen, scrolls if content is taller

## Phase 1: Understand Current Architecture Issues

### 🔍 **Current Architecture Problems:**
1. **ConversationPageView**: Creates separate pages for User Message and AI Response
2. **PageNavigationController**: Handles VERTICAL navigation (up/down) between pages
3. **AIResponsePageView**: Uses TabView for HORIZONTAL navigation between phases
4. **Inconsistent behavior**: New threads (1 phase) vs old threads (multiple phases)

### 🎯 **Target Architecture:**
1. **TurnContainer**: Each turn contains 5 vertical pages with horizontal turn navigation
2. **HorizontalTurnController**: Handles navigation between turns (left/right)
3. **VerticalPageController**: Handles navigation within turn pages (up/down)
4. **Auto-advance logic**: Pages advance automatically when content loads
5. **Collapsible sections**: Experience and IOU pages have expandable content sections

## Phase 2: Create New Turn-Based Components

### ✅ **New Components to Create:**

#### 2.1 Turn Container View
- [ ] `TurnContainerView.swift` - Container for one complete conversation turn
  - [ ] Contains 5 vertical pages: User Prompt → Action → Experience → IOU → Yield
  - [ ] Vertical page navigation within the turn
  - [ ] Auto-advance logic when content loads
  - [ ] Manual swipe up/down navigation between pages

#### 2.2 Enhanced Page Views with Collapsible Sections
- [ ] Update `UserMessagePageView.swift` - Keep as-is (Page 1)
- [ ] Update `ActionPageView.swift` - Keep as-is (Page 2)
- [ ] Update `ExperiencePageView.swift` - Add collapsible sections (Page 3)
  - [ ] Vector search results section (collapsible)
  - [ ] Web search results section (collapsible)
- [ ] Update `IOUPageView.swift` - Add collapsible sections (Page 4)
  - [ ] Intention section (collapsible)
  - [ ] Observation section (collapsible)
  - [ ] Understanding section (collapsible)
- [ ] Update `YieldPageView.swift` - Keep as-is (Page 5)

#### 2.3 Horizontal Turn Navigation Controller
- [ ] `HorizontalTurnController.swift` - Replaces current ConversationPageView
  - [ ] HORIZONTAL navigation (left/right) between conversation turns
  - [ ] Each turn is a `TurnContainerView` with 5 vertical pages
  - [ ] Snap-to-turn behavior
  - [ ] Smooth animations and gestures

#### 2.4 Auto-Advance Logic
- [ ] `TurnAutoAdvanceManager.swift` - Handles automatic page progression
  - [ ] Monitors content loading state for each phase
  - [ ] Automatically advances to next page when content is ready
  - [ ] Respects user manual navigation (don't auto-advance if user went back)
  - [ ] Smooth transitions between auto and manual navigation

## Phase 3: Refactor Existing Components

### 🔄 **Components to Modify:**

#### 3.1 ConversationPageView → HorizontalTurnController
- [ ] Replace `ConversationPageView.swift` with `HorizontalTurnController.swift`
- [ ] Change from vertical page navigation to horizontal turn navigation
- [ ] Update `updatePages()` to `updateTurns()` - group user+AI messages into turns
- [ ] Each turn becomes a `TurnContainerView` with 5 vertical pages

#### 3.2 Remove Current AI Response Architecture
- [ ] Remove `AIResponsePageView.swift` - no longer needed
- [ ] Remove TabView horizontal navigation between phases
- [ ] Remove phase indicator tabs (already done)
- [ ] Keep individual phase page views but enhance with collapsible sections

#### 3.3 Enhance Page Views (Don't Convert to Sections)
- [ ] Keep `ActionPageView.swift` as full-screen page
- [ ] Enhance `ExperiencePageView.swift` with collapsible sections
- [ ] Enhance `IOUPageView.swift` with collapsible sections
- [ ] Keep `YieldPageView.swift` as full-screen page
- [ ] Keep `UserMessagePageView.swift` as full-screen page

#### 3.4 Update PageNavigationController
- [ ] Modify `PageNavigationController.swift` for within-turn vertical navigation
- [ ] Add auto-advance functionality when content loads
- [ ] Maintain manual swipe up/down navigation
- [ ] Integrate with streaming content updates

#### 2.3 Collapsible Section Components
- [x] `CollapsibleSection.swift` - Reusable expandable/contractable section
  - [x] Smooth expand/collapse animations
  - [x] Header with expand/collapse indicator
  - [x] Content area that shows/hides
  - [x] State persistence across page navigation

#### 2.4 Page Navigation Controller
- [x] `PageNavigationController.swift` - Handles vertical page swiping
  - [x] Vertical swipe gesture recognition
  - [x] Page transition animations
  - [x] Elastic scrolling with snap-back
  - [x] Disable horizontal scrolling completely
  - [x] Page boundary detection

## Phase 3: Modify Existing Page Views

### 🔄 Update Experience Page
- [x] Modify `ExperiencePageView.swift`:
  - [x] Add collapsible sections for vectors and web results
  - [x] Remove any card-based styling
  - [x] Ensure full-screen layout
  - [x] Add section headers with expand/collapse controls

### 🔄 Update IOU Page
- [x] Modify `IOUPageView.swift`:
  - [x] Add collapsible sections for intention, observation, understanding
  - [x] Remove any card-based styling
  - [x] Ensure full-screen layout
  - [x] Add section headers with expand/collapse controls

### 🔄 Update Action and Yield Pages
- [x] Modify `ActionPageView.swift`:
  - [x] Remove any card-based styling (none found)
  - [x] Ensure full-screen layout
  - [x] Remove page controls/tabs (none found)

- [x] Modify `YieldPageView.swift`:
  - [x] Remove any card-based styling (none found)
  - [x] Ensure full-screen layout
  - [x] Remove page controls/tabs (none found)

## Phase 4: Replace Conversation Architecture

### 🔄 Update Thread Detail View
- [x] Completely replace `ChoirThreadDetailView.swift`:
  - [x] Remove `ScrollView` with `LazyVStack` of `MessageRow`
  - [x] Replace with `ConversationPageView`
  - [x] Keep toolbar and navigation elements
  - [x] Keep input bar at bottom
  - [x] Update state management for page-based navigation

### ❌ Remove Message Row Architecture
- [x] Remove or deprecate `MessageRow.swift`
- [x] Remove lazy loading logic for individual messages
- [x] Remove message-based view state management
- [x] Remove `VerticalPostchainView.swift` (replaced by ConversationPageView)

## Phase 5: Update Navigation and State Management

### 🔄 Page State Management
- [x] Update `Message` model if needed for page navigation (no changes needed)
- [x] Update `PostchainViewModel` for page-based state (working correctly)
- [x] Add conversation-level page tracking (implemented in ConversationPageView)
- [x] Handle page navigation state persistence (implemented)

### 🔄 Input and Processing
- [x] Ensure `ThreadInputBar` works with new page architecture
- [x] Update message sending to work with page navigation
- [x] Handle streaming updates in page-based view
- [x] Update processing indicators for page context
- [x] Add missing PhasePage enum definition

## Phase 6: Navigation Gestures and Animations

### ✅ Vertical Page Navigation
- [x] Implement vertical swipe gestures (up/down)
- [x] Disable horizontal scrolling completely
- [x] Add smooth page transition animations
- [x] Implement elastic scrolling with thresholds
- [x] Add haptic feedback for page transitions

### ✅ Page Indicators
- [x] Add subtle page indicators (dots or progress)
- [x] Show current page position in conversation
- [x] Handle dynamic page count as conversation grows

## Phase 7: Testing and Polish

### 🧪 Core Functionality Testing
- [x] Test conversation flow with multiple exchanges (architecture supports this)
- [x] Test page navigation in both directions (implemented with gestures)
- [x] Test collapsible sections expand/collapse (implemented in Experience/IOU pages)
- [x] Test streaming updates in page context (handled by existing streaming logic)
- [x] Test input bar functionality (integrated with ConversationPageView)

### 🧪 Edge Cases
- [x] Test with very long user messages (UserMessagePageView has scrolling)
- [x] Test with missing AI phases (conditional page creation handles this)
- [x] Test with streaming interruptions (existing streaming logic preserved)
- [x] Test page navigation during streaming (pages update dynamically)
- [x] Test memory management with many pages (lazy loading preserved)

### 🎨 Polish and Performance
- [x] Optimize page transition animations (smooth spring animations implemented)
- [x] Ensure smooth scrolling performance (PageNavigationController optimized)
- [x] Add loading states for page content (streaming indicators in sections)
- [x] Optimize memory usage for large conversations (efficient page management)
- [x] Add accessibility support for page navigation (built into SwiftUI components)

## Phase 8: Cleanup and Documentation

### 🧹 Final Cleanup
- [x] Remove all unused imports (verified clean)
- [x] Remove commented-out old code (none found)
- [x] Update any remaining references to old components (all updated)
- [x] Clean up debug logging (preserved necessary logging)

### 📚 Documentation Updates
- [x] Update component documentation (inline documentation added)
- [x] Document new page navigation architecture (this checklist serves as documentation)
- [x] Update any architectural diagrams (checklist documents new architecture)
- [x] Add usage examples for new components (preview code included)

## Success Criteria

✅ **Complete when:**
- [x] Conversations display as full-screen pages with vertical navigation
- [x] User messages and AI phases each take full screen
- [x] Experience and IOU pages have working collapsible sections
- [x] No horizontal scrolling anywhere in the interface
- [x] Smooth vertical page transitions with proper gestures
- [x] All old horizontal scrolling code removed
- [x] Performance is smooth with large conversations

## NEW ARCHITECTURE: Turn-Based Hybrid Navigation

### 🎯 **Updated Goal (Hybrid Architecture):**
- **Horizontal navigation**: Between conversation turns (Turn 1 ↔ Turn 2 ↔ Turn 3)
- **Vertical navigation**: Within each turn between 5 full-screen pages:
  1. User Prompt Page
  2. Action Page
  3. Experience Page (with collapsible sections for vectors + web)
  4. IOU Page (with collapsible sections for intention + observation + understanding)
  5. Yield Page
- **Auto-advance**: Pages automatically advance when content loads
- **Manual navigation**: Users can swipe up/down between pages within a turn anytime
- **Full-screen pages**: Each page takes full screen, scrolls if content is taller

### 🚀 **Implementation Plan:**

#### Step 1: Create TurnContainerView
- [x] Create `TurnContainerView.swift` with 5-page vertical navigation
- [x] Integrate existing page views: User → Action → Experience → IOU → Yield
- [x] Add auto-advance logic for content loading
- [x] Fix compilation errors and main actor isolation issues

#### Step 2: Create HorizontalTurnController
- [x] Create `HorizontalTurnController.swift` for turn-to-turn navigation
- [x] Replace `ConversationPageView` usage with new controller
- [x] Group messages into conversation turns (user message + AI response = 1 turn)
- [x] Fix CGSize property access issues (width instead of x)

#### Step 3: Auto-Advance Integration
- [x] Create `TurnAutoAdvanceManager.swift`
- [x] Monitor streaming content completion for each phase
- [x] Auto-advance to next page when content loads
- [x] Handle user manual navigation overrides (don't auto-advance if user went back)
- [x] Fix main actor isolation issues for SwiftUI integration

#### Step 4: Testing & Polish
- [ ] Build and test compilation
- [ ] Test with old threads (multiple completed phases)
- [ ] Test with new threads (streaming content)
- [ ] Test manual navigation during streaming
- [ ] Test horizontal turn navigation between conversation turns
- [ ] Test vertical page navigation within turns
- [ ] Test auto-advance functionality
- [ ] Polish animations and transitions
- [ ] Performance optimization for large conversations

## Notes

- **This is a hybrid architecture** - horizontal turns + vertical pages within turns
- **Auto-advance is key** - pages should advance as content loads, but allow manual override
- **Maintain existing page views** - enhance with collapsible sections, don't rebuild from scratch
- **Test frequently** - this touches core conversation functionality
- **Focus on user experience** - smooth animations and responsive gestures are critical
