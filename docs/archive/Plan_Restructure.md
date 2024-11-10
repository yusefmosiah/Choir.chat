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
# Codebase Restructuring Plan

VERSION restructure_plan:
invariants: {
"Documentation-code alignment",
"Mobile-first architecture",
"Clear state boundaries"
}
assumptions: {
"create-solana-dapp base",
"Documentation completeness",
"Test infrastructure stability"
}
docs_version: "0.2.1"

## Current Status (Oct 28)

Starting from create-solana-dapp template with:
- Next.js frontend
- FastAPI backend
- Anchor program
- Basic testing setup

## Frontend Restructuring (src/)

1. **Core Components**
```typescript
src/
├── components/
│   ├── ChoirChat/        // Main chat container
│   │   ├── ChoirChat.tsx // Three-panel layout
│   │   ├── MessageFlow.tsx // Message & step display
│   │   └── types.ts      // Chat types
│   ├── AIResponse/       // Step visualization
│   │   ├── AIResponse.tsx // Step display
│   │   ├── StepContent.tsx // Step-specific content
│   │   └── types.ts      // Step types
│   ├── PriorPanel/       // Prior handling
│   │   ├── PriorPanel.tsx // Prior display
│   │   ├── PriorCard.tsx  // Prior preview
│   │   └── types.ts      // Prior types
│   └── ui/              // Shared components
```

2. **State Management**
```typescript
src/
├── hooks/
│   ├── useThread.ts      // Thread state
│   ├── useWebSocket.ts   // Real-time comms
│   ├── useChorusCycle.ts // Cycle state & effects
│   └── usePriors.ts      // Prior handling
```

3. **Mobile-First UI**
```typescript
src/
├── styles/
│   ├── BottomSheet.module.css  // Sheet animations
│   ├── MessageFlow.module.css  // Message display
│   └── ChorusPanel.module.css  // Panel layout
```

## Backend Restructuring (api/)

1. **Core Services**
```python
api/
├── app/
│   ├── chorus_cycle.py   # AEIOU-Y cycle
│   ├── database.py      # Qdrant operations
│   ├── websocket.py     # Real-time comms
│   └── models/
│       ├── message.py   # Message types
│       ├── prior.py     # Prior types
│       └── effect.py    # Effect types
```

2. **Chorus Cycle**
```python
chorus_cycle.py
├── ChorusCycle         # Core cycle
│   ├── run_action      # Beginner's mind
│   ├── run_experience  # Get n=80 priors
│   ├── run_intention   # Analyze for goal
│   ├── run_observation # Record in Qdrant
│   ├── run_update      # Loop decision
│   └── run_yield       # Natural citations
```

## Solana Program Restructuring (anchor/)

1. **Core Program**
```rust
programs/basic/src/
├── lib.rs              # Program entry point
├── state/
│   ├── thread.rs       # Thread account
│   ├── message.rs      # Message state
│   └── token.rs        # Token handling
├── instructions/
│   ├── create.rs       # Thread creation
│   ├── submit.rs       # Message submission
│   └── approve.rs      # Approval processing
└── error.rs            # Custom errors
```

2. **Testing Infrastructure**
```typescript
tests/
├── thread.ts           # Thread tests
├── message.ts          # Message tests
└── token.ts           # Token tests
```

## Implementation Priority

1. **Phase 1: Prior Flow (Oct 29)**
   - Vector search implementation
   - Prior display components
   - Semantic recording
   - Citation integration

2. **Phase 2: Effect System (Oct 30)**
   - Effect type cleanup
   - Effect accumulation
   - UI synchronization
   - Error handling

3. **Phase 3: Step Processing (Oct 31)**
   - Step prompts
   - State transitions
   - Real-time updates
   - Loading states

## Testing Strategy

1. **Frontend Tests**
```typescript
// Jest + React Testing Library
- Component rendering
- Hook behavior
- WebSocket interactions
- Mobile gestures
```

2. **Backend Tests**
```python
# Pytest
- WebSocket protocol
- Chorus cycle logic
- State management
- Real-time updates
```

3. **Program Tests**
```rust
// Anchor tests
- Thread operations
- Message flow
- Token distribution
```

## Migration Steps

1. **Frontend Migration**
- Create new component structure
- Implement mobile-first UI
- Set up WebSocket hooks
- Add Chorus cycle state

2. **Backend Migration**
- Set up WebSocket protocol
- Implement Chorus cycle
- Add Qdrant integration
- Configure real-time updates

3. **Program Migration**
- Structure program accounts
- Implement instructions
- Add state management
- Set up tests

## Success Metrics

- Clean component hierarchy
- Mobile-first functionality
- Real-time responsiveness
- Test coverage
- Documentation alignment

Through this restructuring, we'll create a foundation that:
- Enables rapid iteration
- Maintains clear boundaries
- Supports mobile-first design
- Preserves testing integrity
