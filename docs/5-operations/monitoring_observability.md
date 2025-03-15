# Monitoring and Observability

This guide outlines the monitoring and observability strategy for Choir's actor-based architecture, covering metrics collection, logging, alerting, and dashboards.

## Table of Contents

1. [Introduction](#introduction)
2. [Observability Principles](#observability-principles)
3. [Metrics Collection](#metrics-collection)
4. [Logging Strategy](#logging-strategy)
5. [Tracing](#tracing)
6. [Alerting](#alerting)
7. [Dashboards](#dashboards)
8. [Health Checks](#health-checks)
9. [Performance Monitoring](#performance-monitoring)
10. [Implementation](#implementation)

## Introduction

Monitoring and observability are critical for understanding the behavior of distributed actor-based systems. This guide provides strategies for effectively monitoring Choir's actor-based architecture, enabling operators to detect issues, diagnose problems, and optimize performance.

## Observability Principles

The observability strategy for Choir's actor-based architecture is guided by the following principles:

1. **Actor-Centric Observability**: Focus on monitoring individual actors and their interactions.
2. **Message Flow Visibility**: Track message flows between actors to understand system behavior.
3. **State Transparency**: Monitor actor state changes to detect anomalies.
4. **Correlation**: Correlate events across actors to understand system-wide patterns.
5. **Minimal Overhead**: Implement observability with minimal impact on system performance.
6. **Actionable Insights**: Collect metrics that lead to actionable insights.
7. **Holistic View**: Provide a holistic view of the system from different perspectives.

## Metrics Collection

### Actor Metrics

Collect metrics about actors and their behavior:

- **Actor Lifecycle**: Creation, initialization, and destruction
- **Actor Count**: Total number of actors by type
- **Actor State Size**: Memory usage of actor state
- **Actor Processing Time**: Time spent processing messages

```python
# Example actor metrics collection
def collect_actor_metrics(actor):
    metrics.gauge(
        "actor_count",
        1,
        tags={"actor_type": actor.__class__.__name__}
    )

    metrics.gauge(
        "actor_state_size_bytes",
        len(json.dumps(actor.state)),
        tags={"actor_id": actor.id, "actor_type": actor.__class__.__name__}
    )
```

### Message Metrics

Collect metrics about message processing:

- **Message Rate**: Number of messages processed per second
- **Message Processing Time**: Time to process each message
- **Message Size**: Size of messages in bytes
- **Message Queue Length**: Number of messages waiting to be processed

```python
# Example message metrics collection
async def measure_message_processing(actor, message):
    start_time = time.time()

    # Process the message
    response = await actor._process_message(message)

    # Record processing time
    processing_time = time.time() - start_time
    metrics.histogram(
        "message_processing_time_seconds",
        processing_time,
        tags={
            "actor_id": actor.id,
            "actor_type": actor.__class__.__name__,
            "message_type": message.type
        }
    )

    # Record message size
    message_size = len(json.dumps(message.data))
    metrics.histogram(
        "message_size_bytes",
        message_size,
        tags={
            "actor_id": actor.id,
            "actor_type": actor.__class__.__name__,
            "message_type": message.type
        }
    )

    return response
```

### System Metrics

Collect metrics about the overall system:

- **CPU Usage**: CPU usage by the actor system
- **Memory Usage**: Memory usage by the actor system
- **Disk I/O**: Disk I/O operations by the actor system
- **Network I/O**: Network I/O operations by the actor system

```python
# Example system metrics collection
def collect_system_metrics():
    # CPU usage
    metrics.gauge("system_cpu_usage_percent", psutil.cpu_percent())

    # Memory usage
    memory = psutil.virtual_memory()
    metrics.gauge("system_memory_usage_bytes", memory.used)
    metrics.gauge("system_memory_available_bytes", memory.available)

    # Disk I/O
    disk_io = psutil.disk_io_counters()
    metrics.gauge("system_disk_read_bytes", disk_io.read_bytes)
    metrics.gauge("system_disk_write_bytes", disk_io.write_bytes)

    # Network I/O
    net_io = psutil.net_io_counters()
    metrics.gauge("system_network_sent_bytes", net_io.bytes_sent)
    metrics.gauge("system_network_received_bytes", net_io.bytes_recv)
```

### Database Metrics

Collect metrics about database interactions:

- **Query Rate**: Number of queries per second
- **Query Latency**: Time to execute queries
- **Connection Pool**: Size and utilization of connection pools
- **Storage Usage**: Database storage usage

```python
# Example database metrics collection
async def measure_database_query(db, query, params):
    start_time = time.time()

    # Execute the query
    result = await db.execute(query, params)

    # Record query latency
    query_time = time.time() - start_time
    metrics.histogram(
        "database_query_time_seconds",
        query_time,
        tags={"query_type": query.split()[0]}
    )

    return result
```

### Blockchain Metrics

Collect metrics about blockchain interactions:

- **Transaction Rate**: Number of transactions per second
- **Transaction Latency**: Time to confirm transactions
- **Gas Usage**: Gas used by transactions
- **Contract Calls**: Number of contract calls by method

```python
# Example blockchain metrics collection
async def measure_blockchain_transaction(blockchain, transaction):
    start_time = time.time()

    # Submit the transaction
    result = await blockchain.submit_transaction(transaction)

    # Record transaction latency
    transaction_time = time.time() - start_time
    metrics.histogram(
        "blockchain_transaction_time_seconds",
        transaction_time,
        tags={"transaction_type": transaction.type}
    )

    # Record gas usage
    metrics.histogram(
        "blockchain_gas_used",
        result.gas_used,
        tags={"transaction_type": transaction.type}
    )

    return result
```

## Logging Strategy

### Structured Logging

Implement structured logging to enable easy filtering and analysis:

```python
import structlog

logger = structlog.get_logger()

# Actor lifecycle logging
logger.info(
    "actor_created",
    actor_id="actor-123",
    actor_type="ActionPhaseActor"
)

# Message processing logging
logger.info(
    "message_processed",
    actor_id="actor-123",
    message_type="PROCESS_INPUT",
    processing_time_ms=42,
    message_size_bytes=1024
)

# Error logging
logger.error(
    "message_processing_failed",
    actor_id="actor-123",
    message_type="PROCESS_INPUT",
    error="Invalid message format",
    stack_trace=traceback.format_exc()
)
```

### Log Levels

Use appropriate log levels for different types of events:

- **DEBUG**: Detailed information for debugging
- **INFO**: General information about system operation
- **WARNING**: Potential issues that don't affect normal operation
- **ERROR**: Errors that affect normal operation
- **CRITICAL**: Critical errors that require immediate attention

```python
# Debug logging
logger.debug(
    "actor_state_updated",
    actor_id="actor-123",
    state_key="counter",
    old_value=1,
    new_value=2
)

# Info logging
logger.info(
    "actor_message_received",
    actor_id="actor-123",
    message_type="PROCESS_INPUT"
)

# Warning logging
logger.warning(
    "actor_message_queue_growing",
    actor_id="actor-123",
    queue_size=100,
    threshold=50
)

# Error logging
logger.error(
    "actor_message_processing_failed",
    actor_id="actor-123",
    message_type="PROCESS_INPUT",
    error="Invalid message format"
)

# Critical logging
logger.critical(
    "actor_system_unstable",
    error="Database connection lost",
    impact="System is unable to process messages"
)
```

### Contextual Logging

Include context in logs to make them more useful:

```python
# Add context to logs
logger = logger.bind(
    system="choir",
    environment="production",
    version="1.0.0"
)

# Add request context
def process_request(request_id, user_id, request_data):
    request_logger = logger.bind(
        request_id=request_id,
        user_id=user_id
    )

    request_logger.info(
        "request_received",
        request_size_bytes=len(json.dumps(request_data))
    )

    # Process the request

    request_logger.info(
        "request_processed",
        processing_time_ms=42
    )
```

## Tracing

### Distributed Tracing

Implement distributed tracing to track message flows across actors:

```python
import opentelemetry.trace as trace

tracer = trace.get_tracer(__name__)

async def process_message(actor, message):
    # Start a new span for message processing
    with tracer.start_as_current_span(
        "process_message",
        attributes={
            "actor.id": actor.id,
            "actor.type": actor.__class__.__name__,
            "message.type": message.type,
            "message.id": message.id
        }
    ) as span:
        # Process the message
        response = await actor._process_message(message)

        # Add response information to the span
        span.set_attribute("response.type", response.type)
        span.set_attribute("processing.time_ms", span.end_time - span.start_time)

        return response
```

### Trace Propagation

Propagate trace context between actors:

```python
async def send_message(actor, target_actor_id, message):
    # Get the current span context
    current_context = trace.get_current_span().get_span_context()

    # Add trace context to the message
    message.trace_context = {
        "trace_id": current_context.trace_id,
        "span_id": current_context.span_id,
        "trace_flags": current_context.trace_flags
    }

    # Send the message
    response = await actor._send_message(target_actor_id, message)

    return response
```

### Trace Visualization

Visualize traces to understand message flows:

1. Use Jaeger, Zipkin, or other tracing visualization tools
2. Create custom visualizations for actor-specific traces
3. Integrate with existing monitoring dashboards

## Alerting

### Alert Rules

Define alert rules for different scenarios:

```yaml
# Example Prometheus alerting rules
groups:
  - name: actor_system
    rules:
      - alert: HighMessageProcessingTime
        expr: actor_message_processing_time_seconds > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High message processing time"
          description: "Actor {{ $labels.actor_id }} is taking too long to process messages"

      - alert: ActorSystemUnstable
        expr: actor_error_rate > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Actor system unstable"
          description: "Actor system has a high error rate ({{ $value }})"

      - alert: DatabaseConnectionIssues
        expr: database_connection_errors > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Database connection issues"
          description: "Database connection errors detected"
```

### Alert Channels

Configure multiple alert channels for different types of alerts:

1. **Email**: For non-urgent alerts
2. **Slack/Teams**: For team notifications
3. **SMS/Phone**: For critical alerts
4. **PagerDuty/OpsGenie**: For on-call notifications

```yaml
# Example alert channel configuration
receivers:
  - name: email
    email_configs:
      - to: "team@example.com"
        send_resolved: true

  - name: slack
    slack_configs:
      - channel: "#alerts"
        send_resolved: true

  - name: pagerduty
    pagerduty_configs:
      - service_key: "<pagerduty-service-key>"
        send_resolved: true

route:
  receiver: email
  routes:
    - match:
        severity: critical
      receiver: pagerduty
    - match:
        severity: warning
      receiver: slack
```

### Alert Aggregation

Aggregate related alerts to reduce noise:

```yaml
# Example alert aggregation configuration
route:
  group_by: ["alertname", "actor_type"]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: default
```

## Dashboards

### System Overview Dashboard

Create a high-level dashboard showing system health:

1. **Actor System Health**: Overall health of the actor system
2. **Message Processing**: Message rate and latency
3. **Error Rate**: System-wide error rate
4. **Resource Usage**: CPU, memory, disk, and network usage

### Actor Dashboard

Create a dashboard focused on actor metrics:

1. **Actor Count**: Number of actors by type
2. **Actor State Size**: Memory usage of actor state
3. **Message Processing Time**: Time to process messages by actor type
4. **Error Rate**: Error rate by actor type

### Message Flow Dashboard

Create a dashboard showing message flows:

1. **Message Rate**: Number of messages by type
2. **Message Latency**: Time to process messages by type
3. **Message Size**: Size of messages by type
4. **Message Queue Length**: Number of messages waiting to be processed

### Database Dashboard

Create a dashboard for database metrics:

1. **Query Rate**: Number of queries per second
2. **Query Latency**: Time to execute queries
3. **Connection Pool**: Size and utilization of connection pools
4. **Storage Usage**: Database storage usage

### Blockchain Dashboard

Create a dashboard for blockchain metrics:

1. **Transaction Rate**: Number of transactions per second
2. **Transaction Latency**: Time to confirm transactions
3. **Gas Usage**: Gas used by transactions
4. **Contract Calls**: Number of contract calls by method

## Health Checks

### Actor System Health Checks

Implement health checks for the actor system:

```python
async def check_actor_system_health():
    # Check if the actor system is running
    if not actor_system.is_running():
        return {
            "status": "unhealthy",
            "reason": "Actor system is not running"
        }

    # Check if actors are responsive
    try:
        # Send a ping message to a test actor
        response = await actor_system.send_message(
            "test_actor",
            Message(type="PING", data={})
        )

        if response.type != "PONG":
            return {
                "status": "unhealthy",
                "reason": "Test actor is not responsive"
            }
    except Exception as e:
        return {
            "status": "unhealthy",
            "reason": f"Error communicating with test actor: {str(e)}"
        }

    return {
        "status": "healthy"
    }
```

### Database Health Checks

Implement health checks for the database:

```python
async def check_database_health():
    try:
        # Execute a simple query to check database connectivity
        await db.execute("SELECT 1")

        return {
            "status": "healthy"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "reason": f"Database error: {str(e)}"
        }
```

### Blockchain Health Checks

Implement health checks for the blockchain:

```python
async def check_blockchain_health():
    try:
        # Check if the blockchain node is responsive
        status = await blockchain.get_status()

        if not status.is_synced:
            return {
                "status": "degraded",
                "reason": "Blockchain node is not synced"
            }

        return {
            "status": "healthy"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "reason": f"Blockchain error: {str(e)}"
        }
```

### Health Check API

Expose health checks through an API:

```python
@app.get("/health")
async def health():
    # Check all components
    actor_system_health = await check_actor_system_health()
    database_health = await check_database_health()
    blockchain_health = await check_blockchain_health()

    # Determine overall health
    if (actor_system_health["status"] == "unhealthy" or
        database_health["status"] == "unhealthy" or
        blockchain_health["status"] == "unhealthy"):
        status = "unhealthy"
    elif (actor_system_health["status"] == "degraded" or
          database_health["status"] == "degraded" or
          blockchain_health["status"] == "degraded"):
        status = "degraded"
    else:
        status = "healthy"

    return {
        "status": status,
        "components": {
            "actor_system": actor_system_health,
            "database": database_health,
            "blockchain": blockchain_health
        }
    }
```

## Performance Monitoring

### Performance Metrics

Collect performance metrics for critical paths:

1. **End-to-End Latency**: Time from request to response
2. **Component Latency**: Time spent in each component
3. **Resource Usage**: CPU, memory, disk, and network usage during operations
4. **Throughput**: Number of operations per second

```python
async def measure_end_to_end_latency(request_handler, request):
    start_time = time.time()

    # Process the request
    response = await request_handler.process(request)

    # Record end-to-end latency
    latency = time.time() - start_time
    metrics.histogram(
        "request_latency_seconds",
        latency,
        tags={"request_type": request.type}
    )

    return response
```

### Performance Testing

Implement regular performance testing:

1. **Load Testing**: Test system performance under expected load
2. **Stress Testing**: Test system performance under extreme load
3. **Endurance Testing**: Test system performance over extended periods
4. **Spike Testing**: Test system performance under sudden increases in load

```python
async def run_load_test(test_config):
    # Create a test client
    client = TestClient()

    # Create test users
    users = [TestUser(f"user-{i}") for i in range(test_config.user_count)]

    # Run the test
    async with TaskGroup() as group:
        for user in users:
            group.create_task(
                user.run_test_scenario(
                    client,
                    test_config.scenario,
                    test_config.duration
                )
            )

    # Collect and report results
    results = client.get_results()

    return results
```

### Performance Optimization

Use performance metrics to identify and optimize bottlenecks:

1. **Hotspot Analysis**: Identify components with high latency
2. **Resource Analysis**: Identify components with high resource usage
3. **Scaling Analysis**: Identify components that need scaling
4. **Optimization Tracking**: Track the impact of optimizations

## Implementation

### Prometheus Integration

Integrate with Prometheus for metrics collection:

```python
from prometheus_client import Counter, Gauge, Histogram, start_http_server

# Define metrics
message_counter = Counter(
    'actor_messages_total',
    'Total number of messages processed',
    ['actor_type', 'message_type']
)

actor_gauge = Gauge(
    'actor_count',
    'Number of actors',
    ['actor_type']
)

message_latency = Histogram(
    'actor_message_processing_seconds',
    'Time to process messages',
    ['actor_type', 'message_type']
)

# Start metrics server
start_http_server(8000)

# Use metrics in code
def track_message(actor, message, processing_time):
    message_counter.labels(
        actor_type=actor.__class__.__name__,
        message_type=message.type
    ).inc()

    message_latency.labels(
        actor_type=actor.__class__.__name__,
        message_type=message.type
    ).observe(processing_time)
```

### ELK Stack Integration

Integrate with the ELK stack for logging:

```python
import structlog
from structlog.processors import JSONRenderer
from elasticsearch import AsyncElasticsearch

# Configure structlog
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        JSONRenderer()
    ],
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

# Create Elasticsearch client
es_client = AsyncElasticsearch([
    {'host': 'elasticsearch', 'port': 9200}
])

# Create a log handler that sends logs to Elasticsearch
class ElasticsearchLogHandler:
    async def handle(self, log_entry):
        await es_client.index(
            index=f"logs-{datetime.now().strftime('%Y.%m.%d')}",
            body=log_entry
        )

# Use the log handler
logger = structlog.get_logger()
logger = logger.bind(system="choir", environment="production")

logger.info(
    "actor_created",
    actor_id="actor-123",
    actor_type="ActionPhaseActor"
)
```

### Jaeger Integration

Integrate with Jaeger for distributed tracing:

```python
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure the tracer
resource = Resource(attributes={
    SERVICE_NAME: "choir"
})

jaeger_exporter = JaegerExporter(
    agent_host_name="jaeger",
    agent_port=6831,
)

provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(jaeger_exporter)
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

# Get a tracer
tracer = trace.get_tracer(__name__)

# Use the tracer
async def process_message(actor, message):
    with tracer.start_as_current_span(
        "process_message",
        attributes={
            "actor.id": actor.id,
            "actor.type": actor.__class__.__name__,
            "message.type": message.type
        }
    ) as span:
        # Process the message
        response = await actor._process_message(message)

        # Add response information to the span
        span.set_attribute("response.type", response.type)

        return response
```

### Grafana Integration

Integrate with Grafana for dashboards:

```yaml
# Example Grafana dashboard configuration
apiVersion: 1

providers:
  - name: "Choir Dashboards"
    orgId: 1
    folder: "Choir"
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /etc/grafana/provisioning/dashboards
```

## Conclusion

This monitoring and observability strategy provides a comprehensive approach to understanding the behavior of Choir's actor-based architecture. By implementing these practices, you can detect issues, diagnose problems, and optimize performance effectively.

For more detailed information, refer to:

- [Actor Model Overview](../1-concepts/actor_model_overview.md)
- [Message Protocol Reference](../3-implementation/message_protocol_reference.md)
- [State Management Patterns](../3-implementation/state_management_patterns.md)
- [Deployment Guide](deployment_guide.md)
- [Testing Strategy](testing_strategy.md)
