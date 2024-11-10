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
# ChoirChat Component Specification

VERSION choir_chat_system:
invariants: {
"State coherence",
"Message ordering",
"Thread integrity"
}
assumptions: {
"WebSocket availability",
"Wallet connectivity",
"Thread persistence"
}
docs_version: "0.2.1"

## Core State Model

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

// Connection State
connection: {
websocket: Option<WebSocket>,
user: Option<User>,
status: ConnectionStatus,
retryCount: number
},

// UI State
display: {
panelVisible: boolean,
sortOption: SortOption,
sources: Array<Source>
}
}

## State Transitions

1. **Thread Management**

   ```
   SEQUENCE thread_operations:
     create_thread : UserId → Result<Thread>
     select_thread : ThreadId → Result<ThreadState>
     load_messages : ThreadId → Result<Array<Message>>
     handle_error : ThreadError → Result<Recovery>
   ```

2. **Message Handling**

   ```
   SEQUENCE message_operations:
     submit_message : (ThreadId, string) → Result<Message>
     process_response : WebSocketResponse → Result<StateUpdate>
     handle_stream : StreamEvent → Result<MessageUpdate>
     update_history : MessageUpdate → Result<void>
   ```

3. **Connection Management**
   ```
   SEQUENCE connection_lifecycle:
     establish : () → Result<WebSocket>
     authenticate : PublicKey → Result<User>
     maintain : WebSocket → Result<void>
     recover : ConnectionError → Result<void>
   ```

## Effect Handlers

1. **WebSocket Effects**

   ```
   TYPE WebSocketEffect =
     | Connect(config: WebSocketConfig)
     | Send(message: OutgoingMessage)
     | Close(reason: string)
     | Reconnect(attempt: number)

   HANDLER handle_websocket_effect:
     Connect → establish_connection()
     Send → transmit_message()
     Close → cleanup_connection()
     Reconnect → attempt_reconnection()
   ```

2. **Thread Effects**

   ```
   TYPE ThreadEffect =
     | Create(name: string)
     | Select(id: ThreadId)
     | Load(id: ThreadId)
     | Update(state: ThreadState)

   HANDLER handle_thread_effect:
     Create → initiate_thread()
     Select → switch_thread()
     Load → fetch_messages()
     Update → sync_thread_state()
   ```

## Error Recovery

1. **Connection Recovery**

   ```
   SEQUENCE handle_connection_error:
     1. log_error(error)
     2. update_connection_state(error)
     3. attempt_recovery:
        MATCH error:
          Disconnect → reconnect_with_backoff()
          AuthError → reauthenticate_user()
          Timeout → retry_operation()
          _ → notify_user()
   ```

2. **State Recovery**
   ```
   SEQUENCE handle_state_error:
     1. capture_error_state()
     2. rollback_to_last_valid()
     3. replay_missed_events()
     4. verify_consistency()
   ```

## Component Structure

```typescript
COMPONENT ChoirChat():
  // State initialization
  state = use_choir_state<ChoirChatState>()
  effects = use_effect_handler()

  // Lifecycle management
  useEffect(() => {
    establish_connection()
    return cleanup_connection
  }, [])

  // Event handlers
  handle_message = (input: string) => {
    validate_input(input)
    prepare_message(input)
    submit_message(input)
  }

  handle_thread_select = (id: ThreadId) => {
    validate_thread(id)
    switch_thread(id)
    load_messages(id)
  }

  // Render structure
  RETURN (
    <ChatContainer>
      <ThreadList
        threads={state.threads.all}
        selected={state.threads.selected}
        onSelect={handle_thread_select}
        onCreate={handle_thread_create}
      />
      <MessageArea
        messages={state.messages.history}
        streaming={state.messages.streaming}
        onSubmit={handle_message}
      />
      <ChorusPanel
        visible={state.display.panelVisible}
        sources={state.display.sources}
        sortOption={state.display.sortOption}
      />
    </ChatContainer>
  )
```

## State Verification

```typescript
PROPERTY state_invariants:
  // Thread integrity
  FORALL thread IN state.threads:
    thread.messages.ordered
    thread.co_authors.non_empty
    thread.token_balance.non_negative

  // Message ordering
  FORALL msg IN state.messages:
    msg.timestamp.monotonic_increasing
    msg.thread_id.exists_in_threads
    msg.author.authenticated

  // Connection consistency
  state.connection.websocket.connected IMPLIES
    state.connection.user.authenticated AND
    state.connection.status.active
```

## Performance Optimizations

1. **Message Batching**

   ```
   SEQUENCE batch_messages:
     collect_pending(timeout)
     group_by_thread()
     order_within_group()
     transmit_batch()
   ```

2. **State Updates**
   ```
   SEQUENCE optimize_updates:
     debounce_rapid_changes()
     batch_related_updates()
     prioritize_visible_content()
     defer_background_updates()
   ```

This specification provides a complete functional model for the ChoirChat component, with clear state management, effect handling, and error recovery patterns. The implementation should maintain these invariants while providing a smooth user experience.
