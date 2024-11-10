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
# Crystallized WebSocket Server

VERSION websocket_system:
invariants: {
"Connection state integrity",
"Message ordering",
"Error isolation"
}
assumptions: {
"Network reliability",
"State synchronization",
"Client behavior"
}
docs_version: "0.2.1"

## Core Types

```python
TYPE ConnectionState = {
    client_id: str,
    user: Optional[User],
    thread_id: Optional[str],
    status: ConnectionStatus,
    error_state: Optional[ErrorState]
}

TYPE ServerMessage =
    | Init(user: User, threads: List[Thread])
    | ThreadMessages(thread_id: str, messages: List[Message])
    | ChorusResponse(response: Response)
    | Error(error: ErrorInfo)

TYPE ClientMessage =
    | Connect(public_key: str)
    | GetThread(thread_id: str)
    | SubmitPrompt(prompt: str, thread_id: str)
    | CreateThread(user_id: str, name: str)
```

## Pure Message Handlers

```python
FUNCTION handle_client_message(
    state: ConnectionState,
    message: ClientMessage
) -> Tuple[ConnectionState, List[Effect]]:
    MATCH message:
        Connect(public_key) ->
            handle_connect(state, public_key)
        GetThread(thread_id) ->
            handle_get_thread(state, thread_id)
        SubmitPrompt(prompt, thread_id) ->
            handle_submit_prompt(state, prompt, thread_id)
        CreateThread(user_id, name) ->
            handle_create_thread(state, user_id, name)

FUNCTION handle_connect(
    state: ConnectionState,
    public_key: str
) -> Tuple[ConnectionState, List[Effect]]:
    effects = [
        DBEffect(GetUser(public_key)),
        DBEffect(GetThreads(public_key))
    ]
    new_state = state.with_pending_auth(public_key)
    RETURN (new_state, effects)

# Similar handlers for other message types...
```

## Effect Handlers

```python
FUNCTION handle_effects(effects: List[Effect]) -> AsyncGenerator[ServerMessage]:
    FOR effect IN effects:
        MATCH effect:
            DBEffect(op) ->
                result = await database.execute(op)
                YIELD translate_db_result(result)
            ChorusEffect(op) ->
                result = await chorus.execute(op)
                YIELD translate_chorus_result(result)
            WSEffect(op) ->
                YIELD translate_ws_event(op)
```

## Error Correction

```python
FUNCTION handle_connection_error(
    error: Error,
    state: ConnectionState
) -> Tuple[ConnectionState, ServerMessage]:
    MATCH error:
        AuthError ->
            (reset_auth(state), Error("Authentication failed"))
        ThreadError ->
            (reset_thread(state), Error("Thread operation failed"))
        NetworkError ->
            (cache_state(state), Error("Connection interrupted"))
```

## Implementation Bridge

```python
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """
    Pure functional WebSocket handler with effects at the boundaries.
    """
    await websocket.accept()
    state = create_initial_state()

    try:
        while True:
            # Receive message in IO boundary
            data = await websocket.receive_json()

            # Pure message handling
            message = parse_client_message(data)
            new_state, effects = handle_client_message(state, message)

            # Effect handling at boundary
            async for response in handle_effects(effects):
                await websocket.send_json(response.to_json())

            state = new_state

    except WebSocketDisconnect:
        handle_disconnect(state)
    except Exception as e:
        new_state, error_msg = handle_connection_error(e, state)
        await websocket.send_json(error_msg.to_json())
        state = new_state
```
