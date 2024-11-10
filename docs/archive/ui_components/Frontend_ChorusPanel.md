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
# ChorusPanel Component Specification

VERSION chorus_panel_system:
invariants: {
"Step coherence",
"Source ordering",
"State verification"
}
assumptions: {
"Step sequence validity",
"Source availability",
"Sort stability"
}
docs_version: "0.2.1"

## Core State Model

TYPE ChorusPanelState = {
// Step State
steps: {
current: Step,
sequence: Array<Step>,
display: Map<Step, DisplayState>
},

// Bottom Sheet State
sheet: {
isOpen: boolean,
height: "collapsed" | "expanded",
dragStartY: number,
animation: AnimationState
},

// Source State
sources: {
items: Array<Source>,
sortOption: SortOption,
sortOrder: SortOrder,
filters: Set<Filter>,
preview: Option<Source>
},

// Mobile UI State
ui: {
activeTab: TabOption,
safeAreaInsets: EdgeInsets,
scrollLock: boolean
}
}

## Step Display Normalization

```typescript
TYPE StepDisplay = {
  action: {
    icon: "→",
    color: "cyan",
    animation: "slide-right"
  },
  experience: {
    icon: "○",
    color: "blue",
    animation: "pulse"
  },
  intention: {
    icon: "◇",
    color: "purple",
    animation: "fade"
  },
  observation: {
    icon: "□",
    color: "green",
    animation: "scale"
  },
  update: {
    icon: "△",
    color: "yellow",
    animation: "rotate"
  },
  yield: {
    icon: "✓",
    color: "teal",
    animation: "complete"
  }
}
```

## State Verification

```typescript
PROPERTY step_verification:
  // Step sequence validity
  FORALL steps IN panel.steps:
    steps.ordered_by_sequence AND
    steps.all_required_present AND
    steps.no_duplicates

  // Source integrity
  FORALL source IN panel.sources:
    source.metadata.complete AND
    source.embedding.valid AND
    source.content.non_empty

  // Display consistency
  FORALL step IN panel.steps:
    step.display.matches_state AND
    step.animations.complete AND
    step.interactions.responsive
```

## Component Structure

```typescript
COMPONENT ChorusPanel(props: ChorusPanelProps):
  // State management
  state = use_panel_state<ChorusPanelState>()

  // Step rendering
  render_step = (step: Step) => {
    validate_step(step)
    apply_step_style(step)
    handle_step_interaction(step)
    display_step_content(step)
  }

  // Source handling
  handle_sources = (sources: Array<Source>) => {
    validate_sources(sources)
    apply_sort_option(state.sources.sortOption)
    filter_sources(state.sources.filters)
    display_sources()
  }

  // Render structure
  RETURN (
    <PanelContainer>
      <StepSequence>
        {state.steps.sequence.map(render_step)}
      </StepSequence>
      <SourceList
        sources={state.sources.items}
        sortOption={state.sources.sortOption}
        onSort={handle_sort_change}
      />
    </PanelContainer>
  )
```

## Sort Management

```typescript
TYPE SortFunction = {
  date: (a: Source, b: Source) => Date.compare(a.created_at, b.created_at),
  similarity: (a: Source, b: Source) => b.similarity - a.similarity,
  tokens: (a: Source, b: Source) => b.token_value - a.token_value,
  custom: (a: Source, b: Source) => a.custom_order - b.custom_order
}

FUNCTION apply_sort(
  sources: Array<Source>,
  option: SortOption
): Array<Source> {
  validate_sort_option(option)
  sort_function = get_sort_function(option)
  sorted = sources.sort(sort_function)
  verify_sort_result(sorted)
  RETURN sorted
}
```

## Animation Patterns

```typescript
TYPE StepAnimation = {
  enter: {
    from: "opacity-0 scale-95",
    to: "opacity-100 scale-100",
    duration: "300ms"
  },
  exit: {
    from: "opacity-100 scale-100",
    to: "opacity-0 scale-95",
    duration: "200ms"
  },
  transition: "ease-in-out"
}
```

## Error States

```typescript
TYPE PanelError =
  | InvalidStep(step: Step)
  | SourceLoadFailure(source: Source)
  | SortError(option: SortOption)
  | DisplayFailure(component: Component)

FUNCTION handle_panel_error(error: PanelError): Recovery {
  log_error(error)
  update_error_state(error)
  attempt_recovery(error)
  notify_parent(error)
}
```

## Performance Optimizations

```typescript
SEQUENCE optimize_panel:
  1. Virtualize source list
  2. Memoize sort functions
  3. Debounce sort changes
  4. Cache step renders
  5. Lazy load content
```

## Mobile Interactions

```typescript
TYPE MobileGestures = {
  // Bottom sheet gestures
  sheet: {
    drag: {
      threshold: 50,
      animation: "spring(1, 0.9, 0)",
      snapPoints: ["50vh", "85vh", "0vh"]
    },
    dismiss: {
      velocity: 500,
      distance: "25vh"
    }
  },

  // Source preview
  preview: {
    press: {
      delay: 200,
      feedback: "opacity",
      haptics: true
    },
    expand: {
      animation: "slide-up",
      duration: 300
    }
  }
}
```

This specification provides a complete model for the ChorusPanel component, with normalized step display, state verification, and clear interaction patterns. The implementation should maintain these patterns while providing smooth visualization of the Chorus process.
