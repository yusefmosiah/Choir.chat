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
# AIResponse Component Specification

VERSION ai_response_system:
invariants: {
"Step sequence integrity",
"Source coherence",
"Markdown rendering fidelity"
}
assumptions: {
"Step completeness",
"Source availability",
"Markdown safety"
}
docs_version: "0.2.1"

## Core State Model

TYPE AIResponseState = {
// Message State
message: {
content: string,
steps: Array<Step>,
sources: Array<Source>,
status: ResponseStatus
},

// Display State
display: {
activeStep: StepId,
expandedSources: Set<SourceId>,
renderState: RenderState,
error: Option<Error>
},

// Animation State
animation: {
stepTransitions: Map<StepId, AnimationState>,
contentFade: AnimationState,
sourceReveal: AnimationState
}
}

## Step Management

```typescript
TYPE StepState = {
  step: {
    id: StepId,
    type: StepType,
    content: string,
    status: StepStatus
  },
  display: {
    active: boolean,
    complete: boolean,
    error: Option<Error>
  },
  sources: Option<Array<Source>>
}

FUNCTION manage_steps(steps: Array<Step>): Result<StepState[]> {
  validate_step_sequence(steps)
  initialize_step_states(steps)
  handle_step_transitions(steps)
  maintain_step_coherence(steps)
}
```

## Markdown Rendering

```typescript
TYPE MarkdownConfig = {
  sanitize: {
    allowed_tags: Set<string>,
    url_schemes: Set<string>,
    max_depth: number
  },
  plugins: {
    syntax_highlighting: boolean,
    math_rendering: boolean,
    link_preview: boolean
  },
  fallback: {
    render: ReactNode,
    error: ReactNode
  }
}

FUNCTION render_markdown(
  content: string,
  config: MarkdownConfig
): Result<ReactNode> {
  sanitized = sanitize_markdown(content)
  parsed = parse_with_plugins(sanitized)
  enhanced = add_interactivity(parsed)
  validated = verify_output(enhanced)
  RETURN validated
}
```

## Source Integration

```typescript
TYPE SourceDisplay = {
  preview: {
    height: "h-24",
    transition: "transition-all duration-200",
    overflow: "overflow-hidden"
  },
  expanded: {
    height: "auto",
    transition: "transition-all duration-300",
    overflow: "visible"
  }
}

FUNCTION integrate_sources(
  sources: Array<Source>,
  step: StepState
): Result<ReactNode> {
  relevant = filter_relevant_sources(sources, step)
  ordered = sort_by_relevance(relevant)
  rendered = map_to_components(ordered)
  interactive = add_source_interactions(rendered)
  RETURN interactive
}
```

## Error States

```typescript
TYPE AIResponseError =
  | StepSequenceError(step: Step)
  | MarkdownRenderError(content: string)
  | SourceLoadError(source: Source)
  | AnimationError(transition: Transition)
  | StateError(state: AIResponseState)

FUNCTION handle_response_error(error: AIResponseError): Recovery {
  log_detailed_error(error)
  update_error_state(error)
  attempt_graceful_recovery(error)
  notify_parent_component(error)
  render_fallback_ui(error)
}
```

## Mobile-First Component Structure

```typescript
COMPONENT AIResponse(props: AIResponseProps):
  // State & Gestures
  const [state, dispatch] = useResponseState()
  const bottomSheetGestures = useBottomSheetGestures({
    onDrag: handleSheetDrag,
    onSnap: handleSheetSnap,
    snapPoints: ["50vh", "85vh", "0vh"]
  })

  // Mobile-optimized render
  return (
    <div className={styles.response.container}>
      {/* Main Response Content */}
      <div className={styles.response.content}>
        <div className={styles.response.header}>AI</div>
        <div className={styles.response.body}>
          {processedContent}
        </div>
      </div>

      {/* Step Navigation Tabs */}
      <div className={styles.tabs.container}>
        {STEPS.map(step => (
          <Tab
            key={step.id}
            active={state.display.activeStep === step.id}
            icon={step.icon}
            label={step.label}
            onClick={() => handleStepChange(step.id)}
          />
        ))}
      </div>

      {/* Bottom Sheet for Step Details */}
      <BottomSheet
        isOpen={state.display.bottomSheetOpen}
        height={state.display.sheetHeight}
        {...bottomSheetGestures}
      >
        <StepContent
          step={state.display.activeStep}
          sources={state.sources}
          onCitationClick={handleCitationClick}
        />
      </BottomSheet>

      {/* Citation Preview */}
      {state.display.citationPreview && (
        <CitationPreview
          citation={state.display.citationPreview}
          onExpand={handleExpandCitation}
          onDismiss={() => dispatch({ type: "CLEAR_PREVIEW" })}
        />
      )}
    </div>
  )
```

## Animation Patterns

```typescript
TYPE ResponseAnimation = {
  step_transition: {
    exit: "fade-out slide-left",
    enter: "fade-in slide-right",
    duration: "300ms",
    easing: "ease-in-out"
  },
  content_reveal: {
    initial: "opacity-0 scale-95",
    animate: "opacity-100 scale-100",
    duration: "200ms"
  },
  source_expand: {
    initial: "h-0 opacity-0",
    animate: "h-auto opacity-100",
    duration: "250ms"
  }
}
```

## Performance Optimizations

```typescript
SEQUENCE optimize_response:
  1. Virtualize source list
  2. Lazy load markdown renderer
  3. Cache processed content
  4. Debounce step transitions
  5. Preload adjacent steps
```

## State Verification

```typescript
PROPERTY response_invariants:
  // Step integrity
  FORALL step IN steps:
    step.sequence_valid AND
    step.content_present AND
    step.transitions_smooth

  // Source coherence
  FORALL source IN sources:
    source.metadata_complete AND
    source.content_valid AND
    source.display_consistent

  // Render consistency
  FORALL render IN displays:
    render.markdown_safe AND
    render.animations_smooth AND
    render.interactions_responsive
```
