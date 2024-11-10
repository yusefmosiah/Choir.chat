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
docs_version: "0.3.0" # Post-alignment vision, Nov 2024

# Frontend Architecture Plan

VERSION frontend_arch:
invariants: {
"Prior flow integrity",
"Effect coherence",
"UI consistency"
}
assumptions: {
"WebSocket reliability",
"Vector space stability",
"State synchronization"
}
docs_version: "0.3.0" # Post-alignment vision, Nov 2024

## Core Components

1. **AIResponse Component**

   ```typescript
   // Step visualization with prior handling
   interface AIResponseProps {
     message: Message;
     currentStep: ChorusStep;
     steps: Step[];
     sources: Prior[]; // From EXPERIENCE step
   }
   ```

   Key Features:

   - Step-by-step visualization
   - Prior display in EXPERIENCE
   - Citation rendering in YIELD
   - Loading states per step

2. **PriorPanel Component**

   ```typescript
   // Prior display and interaction
   interface PriorPanelProps {
     priors?: Prior[]; // From EXPERIENCE step
     onSelect?: (prior: Prior) => void;
     selectedPriors?: Prior[];
   }
   ```

   Key Features:

   - Show all priors in EXPERIENCE
   - Prior preview cards
   - Citation tooltips
   - Source navigation

3. **MessageFlow Component**

   ```typescript
   // Message and step display
   interface MessageFlowProps {
     messages: Message[];
     currentStep: ChorusStep;
     onMessageSelect: (id: string) => void;
     selectedMessageId: string | null;
   }
   ```

   Key Features:

   - Message rendering
   - Step transitions
   - Prior integration
   - Citation display

## State Management

1. **Chorus Cycle State**

   ```typescript
   // useChorusCycle hook
   interface ChorusState {
     currentStep: ChorusStep;
     steps: Step[];
     priors?: Prior[]; // From EXPERIENCE
     effects: Effect[];
   }
   ```

2. **Effect Handling**

   ```typescript
   // Effect processing
   type Effect = {
     type: "chorus_response" | "error" | "state_update";
     payload: {
       step: ChorusStep;
       content: string;
       priors?: Prior[]; // Only in EXPERIENCE
     };
   };
   ```

3. **WebSocket Integration**
   ```typescript
   // Real-time communication
   interface WebSocketState {
     connected: boolean;
     sendMessage: (msg: WebSocketMessage) => void;
     lastMessage?: WebSocketMessage;
   }
   ```

## UI Flow

1. **Prior Flow**

   ```typescript
   // EXPERIENCE: Show all priors
   <PriorPanel priors={step.priors} />

   // INTENTION: Show goal analysis
   <AIResponse step="intention" content={step.content} />

   // OBSERVATION: Show semantic links
   <AIResponse step="observation" content={step.content} />

   // YIELD: Show citations
   <AIResponse step="yield" content={step.content} />
   ```

2. **Effect Flow**
   ```typescript
   // Effect handling in components
   function handleEffect(effect: Effect) {
     switch (effect.type) {
       case "chorus_response":
         if (effect.payload.step === "experience") {
           updatePriorPanel(effect.payload.priors);
         }
         updateStepDisplay(effect.payload);
         break;
     }
   }
   ```

## Implementation Notes

1. **Prior Handling**

   - Show all priors in EXPERIENCE
   - Enable prior preview
   - Support citation navigation
   - Track semantic links

2. **Effect Processing**

   - Clean effect types
   - Proper accumulation
   - UI synchronization
   - Error handling

3. **State Management**
   - Clear state boundaries
   - Effect-driven updates
   - Consistent UI state
   - Error recovery

## Success Metrics

1. **User Experience**

   - Clear step progression
   - Natural prior flow
   - Smooth transitions
   - Responsive feedback

2. **Technical Quality**

   - Clean component hierarchy
   - Type safety
   - Effect coherence
   - Error handling

3. **Performance**
   - Fast prior loading
   - Smooth animations
   - Efficient updates
   - Memory management

Through this architecture, we create a frontend that:

- Maintains prior flow integrity
- Preserves effect coherence
- Enables natural citations
- Provides clear user feedback
