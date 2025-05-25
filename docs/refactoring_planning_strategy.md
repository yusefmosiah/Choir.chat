# Refactoring Planning Strategy: Interface-First Vibecoding

VERSION refactoring_planning: 2.0 (Interface-First Approach)

## Overview: Interface-First Development Strategy

**Core Insight**: Start with the interface redesign while keeping the service constant. This resets the interaction paradigm immediately, looks pretty, and informs what backend features we actually need.

**Vibecoding Timeline**: Hours, not weeks. Immediate visual impact, progressive enhancement.

## Day 1: Interface-First Foundation

### Hour 0: Bedrock Foundation (30 minutes)
- [ ] Add AWS environment variables to config
- [ ] Test Bedrock provider integration
- [ ] Verify basic functionality works

### Environment Variables Needed
```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
```

### Hours 1-8: PostChain UI Redesign (Interface-First)

### Why Interface First?
- **Immediate Impact**: Users see improvement right away
- **UX Validation**: Test new interaction paradigm before complex backend
- **Momentum**: Pretty UI keeps energy high during development
- **Informed Development**: Interface tells us what backend features matter

### Hours 1-2: Smart Content Categorization

**Goal**: Implement intelligent content hierarchy using existing postchain data

**Current State**: All phase content treated equally in carousel
**New State**: Primary content prominent, secondary contextual, tertiary hidden

```swift
// New file: Choir/Views/PostChain/ContentCategorization.swift
enum ContentCategory {
    case primary    // Fast response, final response - always visible
    case secondary  // Rewards, sources - contextual display
    case tertiary   // Analysis phases - hidden by default
}

struct CategorizedContent {
    let primary: [PostchainPhase]
    let secondary: [PostchainPhase]
    let tertiary: [PostchainPhase]

    init(from message: Message) {
        // Categorize existing phases into hierarchy
        primary = [message.actionPhase, message.yieldPhase].compactMap { $0 }
        secondary = [message.noveltyReward, message.vectorResults].compactMap { $0 }
        tertiary = [message.intentionPhase, message.observationPhase, message.understandingPhase].compactMap { $0 }
    }
}
```

**Implementation Tasks**:
- [ ] Create content categorization logic
- [ ] Design smart card layout components
- [ ] Implement conditional rendering based on content availability
- [ ] Add celebration UI for rewards

### Hours 3-4: Scroll-Triggered Pagination

**Goal**: Replace carousel with frameless paginated scrolling

**Current State**: Horizontal carousel with visible frame constraints
**New State**: Vertical scroll where whole pages slide into focus smoothly

```swift
// New file: Choir/Views/PostChain/ScrollPaginatedView.swift
struct ScrollPaginatedPostchainView: View {
    let message: Message
    @State private var currentPageIndex: Int = 0
    @State private var expandedSections: Set<ContentSection> = []
    @State private var dragOffset: CGFloat = 0

    var availablePages: [PostchainPage] {
        generatePages(for: message, expandedSections: expandedSections)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(availablePages.enumerated()), id: \.offset) { index, page in
                    PostchainPageView(page: page, message: message)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(y: calculatePageOffset(for: index, containerHeight: geometry.size.height))
                        .opacity(calculatePageOpacity(for: index))
                        .allowsHitTesting(index == currentPageIndex)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in dragOffset = value.translation.y }
                    .onEnded { value in handlePageTransition(dragValue: value, containerHeight: geometry.size.height) }
            )
        }
    }
}
```

**Implementation Tasks**:
- [ ] Create page generation logic from existing message data
- [ ] Implement smooth page transitions with spring animations
- [ ] Add page indicators and navigation hints
- [ ] Ensure individual pages can scroll internally

### Hours 5-6: Collapsible Sections & Reward Celebrations

**Goal**: Add expand/collapse functionality and prominent reward display

**Current State**: All content always visible, rewards buried in data
**New State**: Tertiary content collapsible, rewards celebrated prominently

```swift
// New file: Choir/Views/PostChain/CollapsibleSection.swift
struct CollapsibleSection: View {
    let title: String
    let content: String
    let isExpanded: Binding<Bool>
    let category: ContentCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { isExpanded.wrappedValue.toggle() }) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded.wrappedValue {
                Text(content)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded.wrappedValue)
    }
}

// Reward celebration component
struct RewardCelebration: View {
    let reward: RewardInfo

    var body: some View {
        HStack {
            Text("🎉")
                .font(.title)
            VStack(alignment: .leading) {
                Text("Novelty Reward!")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("+\(reward.formattedAmount) CHOIR")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}
```

**Implementation Tasks**:
- [ ] Create collapsible section components
- [ ] Design reward celebration animations
- [ ] Implement smooth expand/collapse transitions
- [ ] Add user preferences for default expanded state

### Hours 7-8: Audio-First Experience (TTS Integration)

**Goal**: Enable hands-free, screen-free interaction with postchain content

**Current State**: Visual-only interface requiring screen attention
**New State**: Audio-first experience with TTS and voice navigation

```swift
// New file: Choir/Services/PostchainAudioManager.swift
import AVFoundation

class PostchainAudioManager: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isPlaying = false
    @Published var currentSection: ContentSection?

    func playAudioScript(for message: Message) {
        let script = generateAudioScript(for: message)

        for section in script.sections {
            let utterance = AVSpeechUtterance(string: section.text)
            utterance.voice = selectVoice(for: section.tone)
            utterance.rate = section.readingSpeed
            synthesizer.speak(utterance)
        }
    }

    private func generateAudioScript(for message: Message) -> AudioScript {
        var script = AudioScript()

        // Primary content - always included
        if let actionContent = message.actionPhase {
            script.addSection(.fastResponse, priority: .high,
                             text: cleanForAudio(actionContent))
        }

        if let yieldContent = message.yieldPhase {
            script.addSection(.finalResponse, priority: .high,
                             text: cleanForAudio(yieldContent))
        }

        // Rewards - celebratory tone
        if let reward = message.noveltyReward {
            script.addSection(.rewards, priority: .medium,
                             text: "Congratulations! You earned \(reward.formattedAmount) CHOIR tokens!",
                             tone: .celebratory)
        }

        return script
    }

    private func cleanForAudio(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "**", with: "") // Remove markdown
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
    }
}
```

**Implementation Tasks**:
- [ ] Create audio script generation from existing message data
- [ ] Implement TTS with natural voice selection
- [ ] Add audio controls (play, pause, skip, speed)
- [ ] Design audio-first navigation patterns

## Day 2: Backend Enhancement

**Now that the interface is beautiful and functional, enhance the backend progressively**

### Hours 1-2: MCP Integration (markdownify-mcp)
- [ ] Implement basic MCP client for tool discovery
- [ ] Integrate markdownify-mcp server for file processing
- [ ] Add file upload UI that flows through new interface
- [ ] Test end-to-end file processing workflow

### Hours 3-4: Query Complexity Routing
- [ ] Create simple complexity classifier (file upload = complex)
- [ ] Implement basic execution plans (simple vs complex)
- [ ] Route file uploads through complex path automatically
- [ ] Add cost optimization for simple queries

### Hours 5-8: Advanced Features
- [ ] Context management and overflow handling
- [ ] Retry mechanisms with model switching
- [ ] Advanced MCP tool integration
- [ ] Performance optimization and monitoring

## Day 3+: Production Features

### Day 3: Relationship Staking & Wallet Languification
- [ ] Implement relationship staking UI and smart contracts
- [ ] Add natural language wallet interface
- [ ] Create voice-controlled wallet operations
- [ ] Test economic mechanics and user flows

### Day 4: Publish Thread Feature
- [ ] Build thread publishing mechanism with CHOIR token costs
- [ ] Create public thread discovery and sharing
- [ ] Implement cross-platform URL sharing
- [ ] Add community feed and search functionality

### Day 5+: Advanced Platform Features
- [ ] Multi-modal content processing (audio, video)
- [ ] Advanced AI orchestration and tool chains
- [ ] Performance optimization and scaling
- [ ] Analytics and user behavior insights

## Interface-First Benefits

### Immediate User Impact
- **Visual Improvement**: Modern, clean interface immediately
- **Better UX**: Content hierarchy makes information digestible
- **Audio Experience**: Hands-free operation for accessibility
- **Reward Celebration**: Users feel good about earning tokens

### Development Benefits
- **Momentum**: Pretty UI keeps energy high during backend work
- **User Feedback**: Can test UX patterns before complex backend
- **Informed Priorities**: Interface tells us what backend features matter
- **Parallel Development**: UI and backend teams can work simultaneously

### Technical Benefits
- **Backward Compatibility**: Existing backend continues working
- **Progressive Enhancement**: Add features without breaking existing
- **Risk Mitigation**: Interface changes are lower risk than service changes
- **Faster Iteration**: UI changes deploy faster than backend changes

## Risk Mitigation

### Technical Risks
1. **MCP Server Reliability**: Implement circuit breakers and fallbacks
2. **Context Window Management**: Gradual rollout with monitoring
3. **Performance Regression**: Benchmark each phase against current system
4. **Complexity Creep**: Strict scope boundaries for each phase

### User Experience Risks
1. **Feature Regression**: Comprehensive testing of existing workflows
2. **Response Time Increase**: Performance budgets for each phase
3. **Reliability Concerns**: Gradual rollout with feature flags

## Success Criteria

### Phase 1 Success
- [ ] Users can upload and process files via MCP
- [ ] File content integrates seamlessly with existing postchain
- [ ] MCP tool calls visible in UI
- [ ] No regression in existing functionality

### Phase 2 Success
- [ ] Simple queries complete 50% faster
- [ ] Complex queries get appropriate tool access
- [ ] Cost per query reduced by 30% overall
- [ ] User satisfaction maintained or improved

### Phase 3 Success
- [ ] System handles 10x current load
- [ ] Individual phase failures don't crash entire workflow
- [ ] New phases can be added without core changes
- [ ] Development velocity increased

### Phase 4 Success
- [ ] System handles files up to 100MB
- [ ] Context overflow handled gracefully
- [ ] 99.9% uptime maintained
- [ ] Ready for advanced features (relationship staking, etc.)


This approach ensures we build incrementally while maintaining system stability and delivering continuous user value.
