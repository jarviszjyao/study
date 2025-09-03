# ECS Safe Scale-In (Asterisk on ECS)

This module implements a safe scale-in workflow for stateful Asterisk ECS tasks using EventBridge + Lambda + DynamoDB with comprehensive error handling, retry logic, and production-grade reliability.

## Architecture Overview

```
[Monitoring & Triggering]
  CloudWatch Metrics (ECS Service CPU <= 30%)
      |
      v
  CloudWatch Alarm (30min low CPU)
      |
      v
  EventBridge Rule (ALARM -> trigger)
      |
      v
+-------------------------------------------------------+
| Lambda: Scale Manager                                 |
|  - Extract cluster/service from alarm event          |
|  - Check cooldown (15min) & hourly limits (2/hour)   |
|  - Verify min capacity & concurrent drain limits     |
|  - Select target ECS Task (newest first)             |
|  - Record/validate DRAINING state (DynamoDB atomic)  |
|  - Call Kamailio Lambda (3 retries + rollback)       |
|  - Call Asterisk HTTP /drain/start (3 retries)       |
|  - Record metrics & structured logging               |
+-------------------------------------------------------+
      |                        |                     |
      |                        |                     |
      v                        v                     v
[DynamoDB: drain_states]   [Metrics]           [Lambda: Kamailio Distributor]
  - taskArn/state/drainId      CloudWatch          - Remove target IP from distro
  - serviceArn/clusterArn      ECS/SafeScaleIn     - 3 retries + DLQ
  - startedAt/completedAt      DrainStarted        - Idempotent operations
  - GSI: service-state-index   DrainingCount       |
  - TTL for cleanup            ScaleInSkipped      |
                              ScaleInErrors        |

                      [Upstream SIP/RTP / Kamailio Distributor]
                                     |
                       (IP removed - no new traffic to target)
                                     |
                                     v

+====================== VPC / ECS Cluster ======================+
|                                                               |
|  ECS Service (desiredCount = N, MinCapacity = M)             |
|    - Task Protection enabled by default                      |
|    - Multiple Asterisk Tasks (Fargate/EC2)                  |
|        [Task A]  [Task B]  [Task C]  ...                    |
|          ^         ^         ^                              |
|          |         |         |                              |
|   (HTTP /drain/start)                                       |
|          |                                                  |
|          +---> Target Task (e.g., Task B)                   |
|                    - Receive drainId/maxDrainSeconds        |
|                    - Reject new calls, process existing     |
|                    - Support /drain/status query            |
|                    - Complete after all calls end (≤4h)     |
|                    - Callback to Scaler Lambda              |
|                                                               |
+===============================================================+

                               |
                               | (drain completion callback)
                               v
+-------------------------------------------------------+
| Lambda: Scaler (Function URL)                         |
|  - Validate Bearer token authentication               |
|  - Verify drainId matches DynamoDB state             |
|  - Read cluster/service ARNs from DynamoDB           |
|  - Check min capacity before decrementing            |
|  - UpdateTaskProtection(taskArn, protection=false)    |
|  - UpdateService(desiredCount = N-1)                  |
|  - Mark SCALED_OUT in DynamoDB                       |
|  - Record completion metrics                          |
+-------------------------------------------------------+

[Observability & Control]
  - CloudWatch Logs (structured with taskArn/drainId/serviceArn)
  - CloudWatch Metrics (DrainStarted, DrainingCount, ScaleInSkipped, etc.)
  - CloudWatch Alarms (Draining timeout, Kamailio failures, auth failures)
  - X-Ray Tracing (optional)
  - DLQ/Retry: Lambda async calls, exponential backoff
  - Rate limiting: Cooldown periods, hourly limits, concurrency limits

[Reliability Features]
  - Idempotent operations with drainId bucketing
  - Atomic state transitions with DynamoDB conditions
  - Rollback on Kamailio/Asterisk failures
  - Min capacity protection via Auto Scaling
  - Comprehensive error handling and metrics
  - Bearer token authentication for callbacks
  - Multi-service support via event-driven architecture
```

## Components

- **CloudWatch Alarm** on ECS Service CPU → **EventBridge Rule** → **Scale Manager Lambda**
- **Scale Manager** selects target ECS task, marks DRAINING in DynamoDB, removes IP from Kamailio, calls Asterisk HTTP /drain/start
- **Asterisk** finishes draining and calls **Scaler Lambda** (Function URL)
- **Scaler** disables task protection and decrements desired count

## Terraform Resources

- DynamoDB table for drain states with GSI (serviceArn, state)
- IAM roles/policies with minimal permissions
- Two Lambdas (scale_manager, scaler) with packaging via archive_file
- Function URL for scaler (shared token auth enforced in code)
- CloudWatch Alarm and EventBridge Rule wired to scale_manager
- CloudWatch metrics and logging permissions

## Variables (see variables.tf)

- `region`, `project_name`, `env`
- `ecs_cluster_name`, `ecs_service_name` (for CloudWatch Alarm)
- `kamailio_lambda_arn`
- `asterisk_http_port`, `asterisk_http_scheme`
- `drain_timeout_seconds`, `drain_concurrency_limit`
- `shared_token` (sensitive)

## Lambda Environment Variables

- `TABLE_NAME`, `KAMAILIO_LAMBDA_ARN`
- `DRAIN_TIMEOUT_SECONDS`, `DRAIN_CONCURRENCY_LIMIT`
- `SCALER_FUNCTION_URL`, `SHARED_TOKEN`
- `ASTERISK_HTTP_PORT`, `ASTERISK_HTTP_SCHEME`
- `COOLDOWN_SECONDS`, `MAX_DRAINS_PER_HOUR`

## Usage

1. Fill in `terraform.tfvars` with required variables
2. `terraform init && terraform apply`
3. Verify CloudWatch Alarm and EventBridge trigger the Scale Manager when CPU is low
4. Monitor CloudWatch metrics and logs for drain operations

## Production Features

- **Multi-service support**: Single deployment handles multiple ECS services via event-driven architecture
- **Comprehensive error handling**: Retry logic, rollback mechanisms, detailed logging
- **Rate limiting**: Cooldown periods, hourly limits, concurrent drain limits
- **Min capacity protection**: Respects Auto Scaling MinCapacity settings
- **Idempotent operations**: Safe to retry, handles duplicate events gracefully
- **Observability**: Structured logging, custom metrics, CloudWatch alarms
- **Security**: Bearer token authentication, minimal IAM permissions


