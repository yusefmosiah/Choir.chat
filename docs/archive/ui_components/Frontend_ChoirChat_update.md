# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.3.0"  # Post-alignment vision, Nov 2024
# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.3.0"  # Post-alignment vision, Nov 2024

# ChoirChat Component with Mobile-First Design

VERSION choir_chat_system:
invariants: {
"State coherence",
"Message ordering",
"Thread integrity",
"Mobile optimization"
}
assumptions: {
"WebSocket availability",
"Gesture support",
"Bottom sheet interactions"
}
docs_version: "0.2.1"

## Core State Model

```typescript
TYPE ChoirChatState = {
  // Thread State
  threads: {
    all: Map<ThreadId, Thread>,
    selected: Option<ThreadId>,
    creating: boolean,
    error: Option<string>
  },

  // Message State
  messages: {
    history: Array<Message>,
    pending: Option<Message>,
    streaming: boolean,
    input: string
  },

  // Chorus Cycle State
  chorus: {
    activeStep: StepEnum,
    bottomSheet: {
      isOpen: boolean,
      height: "collapsed" | "expanded",
      dragStartY: number
    },
    steps: {
      action: StepData,
      experience: StepData,
      intention: StepData,
      observation: StepData,
      update: StepData
    }
  },

  // Mobile UI State
  ui: {
    menuOpen: boolean,
    activeTab: TabId,
    bottomSheetOpen: boolean,
    citationPreview: Option<Citation>,
    safeAreaInsets: EdgeInsets
  }
}
```

## Component Structure

```typescript
COMPONENT ChoirChat():
  // State & Gestures
  const [state, dispatch] = useChoirState()
  const bottomSheetGestures = useBottomSheetGestures({
    onDrag: handleSheetDrag,
    onSnap: handleSheetSnap,
    snapPoints: ["50vh", "85vh", "0vh"]
  })

  // Mobile Layout
  return (
    <div className={styles.container.default}>
      {/* Thread List Menu */}
      <MobileMenu
        isOpen={state.ui.menuOpen}
        threads={state.threads.all}
        onSelect={handleThreadSelect}
      />

      {/* Main Chat Area */}
      <div className={styles.messageThread.container}>
        <Header />
        <MessageList messages={state.messages.history} />
        <ResponseTabs
          activeTab={state.ui.activeTab}
          onTabChange={handleTabChange}
        />
        <MessageInput />
      </div>

      {/* Bottom Sheet for Step Content */}
      <BottomSheet
        isOpen={state.ui.bottomSheetOpen}
        height={state.chorus.bottomSheet.height}
        {...bottomSheetGestures}
      >
        <StepContent
          step={state.chorus.steps[state.ui.activeTab]}
          onCitationClick={handleCitationClick}
        />
      </BottomSheet>

      {/* Citation Preview */}
      {state.ui.citationPreview && (
        <CitationPreview
          citation={state.ui.citationPreview}
          onExpand={handleExpandCitation}
          onDismiss={() => dispatch({ type: "CLEAR_CITATION_PREVIEW" })}
        />
      )}
    </div>
  )
```

## Mobile Interaction Handlers

```typescript
// Bottom Sheet Gestures
FUNCTION handleSheetDrag(event: DragEvent):
  const newHeight = calculateDraggedHeight(event)
  dispatch({ type: "UPDATE_SHEET_HEIGHT", height: newHeight })

FUNCTION handleSheetSnap(point: string):
  dispatch({ type: "SNAP_SHEET_TO", point })

// Tab Navigation
FUNCTION handleTabChange(tab: TabId):
  dispatch({ type: "SET_ACTIVE_TAB", tab })
  if (!state.ui.bottomSheetOpen) {
    dispatch({ type: "OPEN_BOTTOM_SHEET" })
  }

// Citation Handling
FUNCTION handleCitationClick(citation: Citation):
  if (window.innerWidth < 640) {
    dispatch({ type: "SHOW_CITATION_PREVIEW", citation })
  } else {
    dispatch({ type: "EXPAND_CITATION", citation })
  }
```

## Mobile-Optimized Components

```typescript
// Response Tabs Component
COMPONENT ResponseTabs({ activeTab, onTabChange }):
  return (
    <div className={styles.responseTabs.container}>
      <div className={styles.responseTabs.tabs}>
        {STEPS.map(step => (
          <Tab
            key={step.id}
            active={activeTab === step.id}
            icon={step.icon}
            label={step.label}
            onClick={() => onTabChange(step.id)}
          />
        ))}
      </div>
    </div>
  )

// Bottom Sheet Component
COMPONENT BottomSheet({ children, isOpen, height, ...gestures }):
  return (
    <>
      {isOpen && <div className={styles.bottomSheet.overlay} />}
      <div
        className={styles.bottomSheet.container[height]}
        {...gestures}
      >
        <div className={styles.bottomSheet.handle} />
        <div className={styles.bottomSheet.content}>
          {children}
        </div>
      </div>
    </>
  )
```

## Mobile State Updates

```typescript
TYPE MobileAction =
  | { type: "OPEN_BOTTOM_SHEET" }
  | { type: "CLOSE_BOTTOM_SHEET" }
  | { type: "UPDATE_SHEET_HEIGHT", height: string }
  | { type: "SNAP_SHEET_TO", point: string }
  | { type: "SET_ACTIVE_TAB", tab: TabId }
  | { type: "SHOW_CITATION_PREVIEW", citation: Citation }
  | { type: "CLEAR_CITATION_PREVIEW" }
  | { type: "TOGGLE_MENU" }

FUNCTION mobileReducer(state: State, action: MobileAction): State {
  switch (action.type) {
    case "OPEN_BOTTOM_SHEET":
      return { ...state, ui: { ...state.ui, bottomSheetOpen: true }}
    case "UPDATE_SHEET_HEIGHT":
      return {
        ...state,
        chorus: {
          ...state.chorus,
          bottomSheet: { ...state.chorus.bottomSheet, height: action.height }
        }
      }
    // ... handle other mobile actions
  }
}
```

This mobile-first component structure provides:

- Smooth bottom sheet interactions
- Natural tab navigation
- Optimized citation handling
- iOS safe area support
- Responsive adaptations
- Clean state management
