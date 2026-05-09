# CloudWatch Monitoring Setup

## Overview

CloudWatch monitoring is fully integrated into your DevOps infrastructure using Terraform. It provides:

- **Centralized Logging** - All ECS container logs in one place
- **Real-time Dashboards** - Monitor application and infrastructure metrics
- **Automated Alarms** - Get notified of issues automatically
- **Log Retention** - Automatic log cleanup (configurable retention)

## Architecture

```
ECS Task (Docker Container)
    ↓
logs to CloudWatch Log Group
    ↓
(/ecs/devops-task)
    ↓
CloudWatch Dashboard + Metrics
    ↓
CloudWatch Alarms
    ↓
SNS Topic → Email Notifications
```

## Components Deployed

### 1. CloudWatch Log Group
- **Name:** `/ecs/devops-task`
- **Retention:** 7 days (configurable via `log_retention_days`)
- **Stream Prefix:** `ecs`
- **Auto-cleanup:** Old logs automatically deleted after retention period

### 2. CloudWatch Dashboard
- **Name:** `devops-deployment-dashboard`
- **Metrics displayed:**
  - ECS Service Count
  - Running vs Desired task count
  - ALB Target Response Time
  - ALB Request Count
  - Healthy/Unhealthy host count
  - Container logs

### 3. CloudWatch Alarms

#### Unhealthy Targets Alert
- **Triggers:** When ALB has 1+ unhealthy targets
- **Check interval:** Every 60 seconds
- **Actions:** Sends email notification via SNS

#### High Response Time Alert
- **Triggers:** When average response time > 1 second
- **Check interval:** Every 5 minutes
- **Threshold:** 1 second

#### ECS CPU High Alert
- **Triggers:** When task CPU > 80%
- **Check interval:** Every 5 minutes
- **Threshold:** 80%

#### ECS Memory High Alert
- **Triggers:** When task memory > 80%
- **Check interval:** Every 5 minutes
- **Threshold:** 80%

### 4. SNS Topic for Alerts
- **Topic Name:** `devops-alerts`
- **Default email:** `charles@damolak.com` (configurable)
- **Notifications:** Email alerts when alarms trigger

## Accessing Monitoring

### 1. CloudWatch Dashboard

**Via AWS Console:**
```
AWS Console → CloudWatch → Dashboards → devops-deployment-dashboard
```

**Or direct link (after deployment):**
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=devops-deployment-dashboard
```

### 2. View Container Logs

**Via AWS Console:**
```
AWS Console → CloudWatch → Log Groups → /ecs/devops-task
```

**Via AWS CLI:**
```bash
# Tail logs in real-time
aws logs tail /ecs/devops-task --follow

# View logs from last hour
aws logs tail /ecs/devops-task --since 1h

# Search for errors
aws logs filter-log-events \
  --log-group-name /ecs/devops-task \
  --filter-pattern "ERROR"
```

### 3. View Alarms

**Via AWS Console:**
```
AWS Console → CloudWatch → Alarms → All Alarms
```

**Via AWS CLI:**
```bash
# List all alarms
aws cloudwatch describe-alarms

# List alarm history
aws cloudwatch describe-alarm-history \
  --alarm-name devops-unhealthy-targets-alert
```

## Configuring Alarms

### Change Notification Email

Edit `terraform/variables.tf` or `terraform.tfvars`:
```hcl
variable "alarm_email" {
  default = "your-email@company.com"
}
```

Then apply:
```bash
terraform apply -auto-approve
```

**Note:** After updating, check your email for SNS subscription confirmation.

### Change Log Retention

Edit `terraform/variables.tf`:
```hcl
variable "log_retention_days" {
  default = 30  # Change from 7 to 30 days
}
```

Then apply:
```bash
terraform apply -auto-approve
```

### Add New Metrics to Dashboard

Edit `terraform/modules/monitoring/main.tf` and add metrics to the dashboard widget:

```hcl
metrics = [
  ["AWS/ECS", "ServiceCount", { stat = "Average" }],
  ["AWS/Lambda", "Duration", { stat = "Average" }],  # Add new metric
  # ...
]
```

## Interpreting Metrics

### ECS Metrics
| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| CPU Utilization | < 30% | 30-60% | > 80% |
| Memory Utilization | < 40% | 40-70% | > 80% |
| Running Count | = Desired | < Desired | 0 |

### ALB Metrics
| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| Response Time | < 200ms | 200-800ms | > 1000ms |
| Healthy Hosts | > 0 | 1 | 0 |
| Request Count | Stable | Spike | Crash |

### Log Patterns
```
[ERROR] - Application error occurred
[WARN] - Potential issue
[INFO] - Normal operation
[DEBUG] - Detailed information (usually in dev)
```

## Troubleshooting

### No logs appearing in CloudWatch

**Check:**
1. ECS task is running: `aws ecs describe-tasks --cluster devops-cluster --tasks <task-arn>`
2. IAM role has logs permission: Already added in Terraform
3. Log group exists: `aws logs describe-log-groups`

**Fix:**
```bash
# Force new deployment
aws ecs update-service \
  --cluster devops-cluster \
  --service devops-service \
  --force-new-deployment
```

### Alarms not triggering

**Check:**
1. Metrics are being sent: Check CloudWatch Metrics page
2. Alarm state: `aws cloudwatch describe-alarms`
3. SNS subscription confirmed: Check email

**Common cause:** SNS email not confirmed - check email inbox for confirmation link.

### High CPU/Memory usage

**Quick fix:**
```bash
# View running tasks
aws ecs list-tasks --cluster devops-cluster

# Check container logs
aws logs tail /ecs/devops-task --follow

# Increase task resources in terraform/modules/ecs/main.tf
cpu    = 512  # Changed from 256
memory = 1024 # Changed from 512
```

## Queries for Log Insights

### CloudWatch Logs Insights (Advanced)

**Search for HTTP errors:**
```
fields @timestamp, @message
| filter @message like /5\d\d/
| stats count() as error_count by @message
```

**Count requests by status:**
```
fields @message
| stats count() as requests by @message
```

**Find slowest requests:**
```
fields @duration
| stats max(@duration) as max_duration, avg(@duration) as avg_duration
```

## Cost Optimization

### Log Retention
- Current: 7 days ($0.50 per GB per month)
- Recommendation for prod: 30 days
- Archive to S3 after 30 days for long-term retention

### Metrics
- ECS metrics: Free tier
- Custom metrics: $0.30 per metric
- Dashboard: Free

### Alarms
- Free tier: 10 alarms
- Beyond: $0.10 per alarm/month

## Next Steps

1. ✅ Deploy monitoring: `terraform apply`
2. ✅ Confirm SNS subscription (check email)
3. ✅ Access dashboard and verify metrics
4. ✅ Test alarm by manually unhealthy target
5. ✅ Set up log insights queries for common issues
6. ✅ Integrate with your team's alerting system (PagerDuty, Slack, etc.)

## Integration with Other Tools

### Slack Notifications

Create Lambda function to forward SNS to Slack:
```bash
aws lambda create-function \
  --function-name cloudwatch-slack \
  --runtime python3.11 \
  --handler index.handler \
  --environment "SLACK_WEBHOOK_URL=https://hooks.slack.com/..."
```

### PagerDuty Integration

1. Create PagerDuty service
2. Get integration key
3. Update SNS subscription endpoint to PagerDuty API

### Custom Dashboards

Use CloudWatch API to create custom dashboards:
```bash
aws cloudwatch put-dashboard \
  --dashboard-name custom-dashboard \
  --dashboard-body file://dashboard.json
```

## References

- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [CloudWatch Logs Insights Queries](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html)
- [ECS CloudWatch Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/EventTypes.html)
