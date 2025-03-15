# Deployment Guide

This guide provides instructions for deploying Choir's actor-based architecture in various environments, including Docker, Phala Network, and traditional cloud providers.

## Table of Contents

1. [Introduction](#introduction)
2. [Deployment Architecture](#deployment-architecture)
3. [Docker Deployment](#docker-deployment)
4. [Phala Network Deployment](#phala-network-deployment)
5. [Cloud Provider Deployment](#cloud-provider-deployment)
6. [Scaling Considerations](#scaling-considerations)
7. [Monitoring and Observability](#monitoring-and-observability)
8. [Backup and Recovery](#backup-and-recovery)

## Introduction

Choir's actor-based architecture is designed to be deployed in a variety of environments, from local development to production. This guide covers the deployment process for each environment, with a focus on best practices for security, scalability, and reliability.

## Deployment Architecture

The deployment architecture consists of several components:

1. **Actor System**: The core actor-based system
2. **Database**: libSQL/Turso for state persistence
3. **Vector Database**: For semantic search and retrieval
4. **Blockchain Node**: For integration with the Sui blockchain
5. **API Gateway**: For external access to the system
6. **Monitoring Stack**: For observability and alerting

### Component Diagram

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   API Gateway   │────▶│   Actor System  │────▶│    Database     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │  │  │
                ┌──────────────┘  │  └──────────────┐
                ▼                 ▼                 ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Vector Database │     │ Blockchain Node │     │ Monitoring Stack│
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Docker Deployment

### Prerequisites

- Docker Engine 20.10.0 or later
- Docker Compose 2.0.0 or later
- Git

### Step 1: Clone the Repository

```bash
git clone https://github.com/your-org/choir.git
cd choir
```

### Step 2: Configure Environment Variables

Create a `.env` file based on the provided template:

```bash
cp .env.example .env
```

Edit the `.env` file to configure:

- Database connection details
- API keys for external services
- Blockchain configuration
- Logging and monitoring settings

### Step 3: Build and Start the Containers

```bash
docker-compose build
docker-compose up -d
```

This will start the following containers:

- `choir-api`: The API gateway
- `choir-actor-system`: The actor system
- `choir-db`: The libSQL/Turso database
- `choir-vector-db`: The vector database
- `choir-blockchain`: The blockchain node
- `choir-monitoring`: The monitoring stack

### Step 4: Verify Deployment

Check that all containers are running:

```bash
docker-compose ps
```

Verify that the API is accessible:

```bash
curl http://localhost:8000/health
```

### Step 5: Initialize the System

Run the initialization script to set up the actor system:

```bash
docker-compose exec choir-actor-system python -m scripts.initialize
```

## Phala Network Deployment

[Phala Network](https://phala.network/) provides a confidential computing platform that can be used to deploy Choir in a privacy-preserving environment.

### Prerequisites

- Phala Network account
- Phala CLI tools
- Docker

### Step 1: Prepare the Deployment Package

Create a deployment package for Phala:

```bash
./scripts/build_phala_package.sh
```

This will create a `choir-phala.tar.gz` file containing the necessary files for deployment.

### Step 2: Upload to Phala

Upload the deployment package to Phala:

```bash
phala upload choir-phala.tar.gz
```

### Step 3: Configure the Deployment

Configure the deployment parameters:

```bash
phala configure choir \
  --cpu 4 \
  --memory 8G \
  --storage 100G \
  --env-file .env.phala
```

### Step 4: Deploy the Application

Deploy the application to Phala:

```bash
phala deploy choir
```

### Step 5: Verify Deployment

Verify that the deployment was successful:

```bash
phala status choir
```

## Cloud Provider Deployment

### AWS Deployment

#### Prerequisites

- AWS account
- AWS CLI configured
- Terraform 1.0.0 or later

#### Step 1: Configure Terraform Variables

Create a `terraform.tfvars` file based on the provided template:

```bash
cp terraform/aws/terraform.tfvars.example terraform/aws/terraform.tfvars
```

Edit the `terraform.tfvars` file to configure:

- AWS region
- Instance types
- Database configuration
- Networking settings

#### Step 2: Initialize Terraform

```bash
cd terraform/aws
terraform init
```

#### Step 3: Apply Terraform Configuration

```bash
terraform apply
```

This will create the following resources:

- EC2 instances for the actor system
- RDS instance for the database
- ElastiCache for caching
- S3 buckets for storage
- CloudWatch for monitoring
- IAM roles and policies

#### Step 4: Deploy the Application

Deploy the application to the created infrastructure:

```bash
./scripts/deploy_aws.sh
```

### Google Cloud Platform Deployment

Similar steps for GCP deployment...

### Azure Deployment

Similar steps for Azure deployment...

## Scaling Considerations

### Horizontal Scaling

The actor-based architecture is designed to scale horizontally:

1. **Actor System Scaling**: Add more actor system nodes to handle increased load
2. **Database Scaling**: Scale the database using libSQL/Turso's replication features
3. **Vector Database Scaling**: Add more vector database nodes for increased capacity
4. **API Gateway Scaling**: Scale the API gateway using load balancers

### Vertical Scaling

For components that benefit from vertical scaling:

1. **Actor System**: Increase CPU and memory for compute-intensive workloads
2. **Database**: Increase storage and memory for data-intensive workloads
3. **Vector Database**: Increase memory for large vector operations

### Auto-Scaling

Configure auto-scaling for dynamic workloads:

```yaml
# Example AWS Auto Scaling configuration
auto_scaling_group:
  min_size: 2
  max_size: 10
  desired_capacity: 2
  scaling_policies:
    - name: scale_up
      adjustment_type: ChangeInCapacity
      scaling_adjustment: 1
      cooldown: 300
      alarm_name: high_cpu_utilization
    - name: scale_down
      adjustment_type: ChangeInCapacity
      scaling_adjustment: -1
      cooldown: 300
      alarm_name: low_cpu_utilization
```

## Monitoring and Observability

### Metrics Collection

Collect metrics using Prometheus:

1. **Actor System Metrics**: Actor creation/destruction, message processing, state size
2. **Database Metrics**: Query performance, connection count, storage usage
3. **API Gateway Metrics**: Request rate, latency, error rate
4. **System Metrics**: CPU, memory, disk, network

### Logging

Implement structured logging:

```python
import structlog

logger = structlog.get_logger()

logger.info(
    "actor_message_processed",
    actor_id="actor-123",
    message_type="PROCESS_INPUT",
    processing_time_ms=42
)
```

### Alerting

Configure alerts for critical conditions:

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
```

### Dashboards

Create dashboards for monitoring:

1. **System Overview**: High-level system health
2. **Actor System**: Detailed actor metrics
3. **Database Performance**: Query performance and storage usage
4. **API Gateway**: Request rates and latencies

## Backup and Recovery

### Database Backup

Configure regular database backups:

```bash
# Example backup script
#!/bin/bash
DATE=$(date +%Y-%m-%d-%H-%M-%S)
BACKUP_DIR=/var/backups/choir

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Backup the database
turso backup $CHOIR_DB_URL > $BACKUP_DIR/choir-db-$DATE.sql

# Compress the backup
gzip $BACKUP_DIR/choir-db-$DATE.sql

# Rotate backups (keep last 7 days)
find $BACKUP_DIR -name "choir-db-*.sql.gz" -mtime +7 -delete
```

### State Recovery

Implement state recovery procedures:

1. **Actor State Recovery**: Restore actor state from database backups
2. **System State Recovery**: Rebuild the actor system from persistent storage
3. **Blockchain State Recovery**: Sync with the blockchain to recover state

### Disaster Recovery

Create a disaster recovery plan:

1. **Backup Verification**: Regularly verify that backups can be restored
2. **Recovery Testing**: Test recovery procedures in a staging environment
3. **Documentation**: Document recovery procedures for different failure scenarios

## Conclusion

This guide provides a foundation for deploying Choir's actor-based architecture in various environments. By following these best practices, you can create a secure, scalable, and reliable deployment.

For more detailed information, refer to:

- [Actor Model Overview](../1-concepts/actor_model_overview.md)
- [State Management Patterns](../3-implementation/state_management_patterns.md)
- [Monitoring and Observability Guide](monitoring_observability.md)
