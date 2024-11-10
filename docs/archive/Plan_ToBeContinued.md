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
# Plan To Be Continued

## Current Status

### Frontend
1. Layout structure complete:
   - 3-column layout with ThreadList, MessageFlow, and PriorPanel
   - Fixed input at bottom of center column
   - Proper height constraints and overflow handling

2. Component Structure:
   - AIResponse component ready for step visualization
   - MessageFlow handling user/AI messages
   - PriorPanel ready for prior display

3. State Management:
   - useWebSocket hook for real-time updates
   - useThread hook for thread state
   - useChorusCycle hook for cycle state

### Backend
1. Database Setup:
   - Qdrant collections configured:
     - messages (1536d vectors)
     - chat_threads (1536d vectors)
     - users (1536d vectors)
   - Collection operations implemented

2. Initial Structure:
   - WebSocket handler ready
   - Basic chorus cycle implemented
   - Database client with vector search

## Next Steps

### 1. Chorus Cycle Implementation

1. **ACTION**
   - [ ] Implement "beginner's mind" prompt
   - [ ] Add confidence scoring
   - [ ] Setup effect generation
   - [ ] Add error handling

2. **EXPERIENCE**
   - [ ] Implement vector search (n=80)
   - [ ] Format priors for context
   - [ ] Return both synthesis and priors
   - [ ] No filtering at this stage

3. **INTENTION**
   - [ ] Analyze priors for user's goal
   - [ ] Consider how priors support intent
   - [ ] Return intent analysis
   - [ ] No filtering yet

4. **OBSERVATION**
   - [ ] Record semantic links in Qdrant
   - [ ] Store which priors were cited
   - [ ] Build knowledge graph
   - [ ] Return observation analysis

5. **UPDATE**
   - [ ] Implement loop/proceed decision
   - [ ] Add confidence threshold
   - [ ] Track decision reasoning
   - [ ] Handle state transitions

6. **YIELD**
   - [ ] Natural citation integration
   - [ ] Markdown formatting
   - [ ] Citation quality checks
   - [ ] Final response synthesis

### 2. Prior Flow Implementation

1. **Vector Search**
   - [ ] Optimize search parameters
   - [ ] Handle embedding errors
   - [ ] Add result caching
   - [ ] Improve ranking

2. **Semantic Recording**
   - [ ] Design semantic links schema
   - [ ] Implement recording in Qdrant
   - [ ] Add metadata tracking
   - [ ] Enable future retrieval

3. **Citation Integration**
   - [ ] Design citation format
   - [ ] Implement natural integration
   - [ ] Add citation previews
   - [ ] Handle citation navigation

### 3. Effect System

1. **Effect Generation**
   - [ ] Clean up effect types
   - [ ] Implement accumulation
   - [ ] Add error effects
   - [ ] Handle state updates

2. **Effect Handling**
   - [ ] Update UI components
   - [ ] Handle WebSocket events
   - [ ] Add error recovery
   - [ ] Maintain state coherence

### 4. Frontend Components

1. **AIResponse**
   - [ ] Step visualization
   - [ ] Prior display
   - [ ] Citation rendering
   - [ ] Loading states

2. **PriorPanel**
   - [ ] Prior list display
   - [ ] Citation preview
   - [ ] Prior filtering
   - [ ] Selection handling

## Immediate Focus
1. Complete prior flow implementation
2. Add semantic recording
3. Clean up effect system
4. Enhance citation handling

## Notes
- Keep prior flow clean and simple
- Focus on semantic recording
- Maintain effect coherence
- Enable natural citations
