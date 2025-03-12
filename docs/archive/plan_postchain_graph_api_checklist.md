# 🌀 PostChain Graph API Development Plan

VERSION postchain_graph_api: 1.0

## 📊 Exploration Paths

| Path Name                              | Description                                                 | Strengths                                                       | Weaknesses                                                 | Potential Surprises                    |
| -------------------------------------- | ----------------------------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------- | -------------------------------------- |
| **🔄 Incremental Phase Builder**       | Build API endpoints phase-by-phase (Action→Experience→etc.) | - Clear progression<br>- Easy to test<br>- Matches mental model | - Potential rework across phases<br>- Might duplicate code | Unexpected dependencies between phases |
| **🔌 Streaming Architecture Refactor** | Focus on streaming infrastructure first, then add phases    | - Solid foundation<br>- Consistent approach                     | - Delays visible progress<br>- More abstract               | Streaming needs may vary by phase      |
| **📱 Frontend-Driven Development**     | Build Swift frontend and API together in lockstep           | - Immediate feedback<br>- User-focused                          | - Complexity of dual-track dev<br>- Context switching      | Discovering frontend needs too late    |

**Selected Path: 🔄 Incremental Phase Builder** - Aligns with our goals and provides the clearest progression with visible milestones.

## 🗺️ PostChain Graph API Development Map

[User Query] → [API Gateway]
↓
[Action Phase] → [Basic Response]
↓
[Experience 1] → [Vector DB Enrichment]
↓
[Experience 2] → [Web Search Enrichment]
↓
[Intention Phase] → [User Intent Alignment]
↓
[Observation] → [Semantic Connections]
↓
[Understanding] → [Decision Loop]
↓
[Yield] → [Final Response]
↓
[Swift Client]

## ✅ Development Checklist

### 📋 Phase 1: Foundation & Action Phase

- [ ] Review existing postchain_graph implementation
- [ ] Document core API schema and endpoints
- [ ] Create basic FastAPI route for Action phase only
- [ ] Implement basic conversation context management
- [ ] Add streaming support
- [ ] Test Action phase endpoint with Postman/curl
- [ ] Implement basic Swift client connectivity given existing interface
- [ ] Implement multi-turn conversation support

### 📋 Phase 2: Experience Enrichment

- [ ] Add Experience 1 (Vector DB/Qdrant) integration
- [ ] Implement proper presentation of vector search results
- [ ] Add Experience 2 (Web Search) integration
- [ ] Format search results with clickable links
- [ ] Test combined Action+Experience flow
- [ ] Update Swift client to display enriched responses

### 📋 Phase 3: Intention & Beyond

- [ ] Implement Intention phase API endpoint
- [ ] Add Observation phase with semantic linking
- [ ] Refactor Understanding phase with improved loop logic
- [ ] Implement Yield phase for final response generation
- [ ] Add comprehensive error handling and fallbacks
- [ ] Complete end-to-end testing of full PostChain
- [ ] Finalize Swift client integration

### 📋 Phase 4: Advanced Features

- [ ] Add context management with model-specific limits
- [ ] Implement document/file upload support
- [ ] Performance optimization and monitoring

## 🚩 Current Status & Next Steps

### Current Status:

- ✅ Initial postchain_graph implementation (900+ lines)
- ❌ Streaming not working correctly
- ❌ Missing multi-turn conversation support
- ❌ Need better context management
- ❌ No document upload functionality

### Immediate Next Steps:

1. Simplify existing postchain_graph code
2. Create first Action-only API endpoint
3. Test with basic client
4. Add Experience phase (Vector DB) integration
5. Implement phase-level (not token-level) streaming

## 🧙 Implementation Notes

### API Design Considerations

- Use FastAPI for async endpoint handling
- Implement phase-level streaming using SSE (Server-Sent Events)
- Design conversation context manager with token counting
- Plan for model-specific adaptations in Understanding phase

### Context Management Strategy

- Implement a sliding window approach for conversation history
- Store full history in persistent storage (DB)
- Fetch relevant context on demand based on semantic search
- Implement aggressive summarization for maintaining context

### Potential Implementation Risks

- Different models having incompatible input/output formats
- Exceeding context windows during complex chains
- Async complexity when integrating multiple services
- Swift client struggling with partial/incremental updates

## Next Development Session Plan

1. Start with a minimal Action-phase endpoint
2. Test thoroughly with simple queries
3. Add Experience phase (Vector DB) integration
4. Implement basic context management
5. Connect Swift client to first working endpoint

This plan emphasizes incremental development while properly documenting the API structure and implementation decisions along the way.
