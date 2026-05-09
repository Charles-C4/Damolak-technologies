# CI/CD Pipeline Setup Guide

## Overview

This GitHub Actions pipeline automates the complete deployment process:
1. **Build** - Compiles Docker image
2. **Test** - Validates nginx config and container health
3. **Deploy** - Pushes to ECR and updates ECS service

## Trigger Behavior

| Branch | Event | Behavior |
|--------|-------|----------|
| `main` | Push | Build → Test → Push → Deploy |
| `develop` | Push | Build → Test → Push (no deploy) |
| Any | Pull Request | Build → Test only |

## Prerequisites

### 1. Create GitHub Repository Secrets

Go to your GitHub repository **Settings → Secrets and variables → Actions** and add:

| Secret | Value | Source |
|--------|-------|--------|
| `AWS_ACCESS_KEY_ID` | CI/CD user access key | From Terraform output: `cicd_access_key_id` |
| `AWS_SECRET_ACCESS_KEY` | CI/CD user secret key | From Terraform output: `cicd_access_key_secret` |
| `AWS_ACCOUNT_ID` | Your AWS account ID | `489270049918` (from your code) |

### 2. Retrieve Credentials from Terraform

After applying the IAM terraform code, run:

```bash
cd terraform
terraform output cicd_access_key_id
terraform output cicd_access_key_secret
terraform output cicd_user_name
```

Or retrieve from AWS Console:
- Go to **IAM → Users → devops-cicd-user → Security credentials**
- Create access key if needed

## Pipeline Stages

### Stage 1: Build
- Checks out code
- Builds Docker image from `docker/Dockerfile`
- Tags with commit SHA and `latest`
- Runs nginx configuration validation
- Tests container startup and health check

### Stage 2: Push (Main/Develop only)
- Logs in to Amazon ECR
- Pushes Docker image to ECR repository
- Tags with both commit SHA and `latest`

### Stage 3: Deploy (Main only)
- Updates ECS service with new image
- Forces new deployment
- Waits for service to stabilize (max 5 minutes)
- Verifies running count matches desired count
- Outputs deployment status

## GitHub Actions Secrets Configuration

1. Go to: **Repository → Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Add each secret from the table above

### Example Setup:
```
AWS_ACCESS_KEY_ID: AKIA2EXAMPLE1234567
AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG+39XXXXXEXAMPLE
AWS_ACCOUNT_ID: 489270049918
```

## Manual Deployment

If needed, you can manually trigger the workflow:

1. Go to **Actions** tab
2. Select **"Build, Test & Deploy"** workflow
3. Click **Run workflow**
4. Select branch and click **Run workflow**

## Monitoring Deployment

### Via GitHub Actions
- View live logs in **Actions** tab
- Each step shows detailed output

### Via AWS Console

Check deployment status:
```bash
# View service status
aws ecs describe-services \
  --cluster devops-cluster \
  --services devops-service \
  --region us-east-1

# View task logs
aws ecs describe-tasks \
  --cluster devops-cluster \
  --tasks <task-arn> \
  --region us-east-1

# Stream logs
aws logs tail /ecs/devops-task --follow
```

## Troubleshooting

### Build Fails
- Check Docker configuration: `docker/Dockerfile`
- Verify app files exist: `app/site/`
- Check nginx config: `docker/nginx.conf`

### Tests Fail
- Container health check failing: Check nginx config and port 80
- Nginx config validation error: Run `docker run -v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro nginx nginx -t`

### Push Fails
- AWS credentials invalid: Regenerate IAM access keys
- ECR repository doesn't exist: Terraform should create it via `modules/ecr`
- Permission denied: Check IAM user has ECR push policy

### Deploy Fails
- ECS service doesn't exist: Ensure Terraform applied successfully
- Service won't stabilize: Check ECS task logs, security groups, ALB health checks
- New image not pulling: Verify ECR image URI matches ECS task definition

## Best Practices

1. **Always test before main branch**
  - Push to `develop` first to test without deploying
  - Use pull requests for code review

2. **Monitor deployment status**
  - Check GitHub Actions logs
  - Verify ALB shows healthy targets
  - Test the deployment manually

3. **Rollback procedure**
  - Push previous commit to main
  - Pipeline redeploys automatically
  - Or manually run: `aws ecs update-service --cluster devops-cluster --service devops-service --force-new-deployment`

4. **Security**
  - Rotate IAM access keys regularly
  - Use least privilege permissions
  - Never commit secrets to repository

## Environment Variables

All configurable in `.github/workflows/deploy.yml`:

```yaml
env:
  AWS_REGION: us-east-1           # AWS region
  ECR_REPOSITORY: devops-static   # ECR repo name
  ECS_CLUSTER: devops-cluster     # ECS cluster name
  ECS_SERVICE: devops-service     # ECS service name
```

## Next Steps

1. ✅ Push credentials to GitHub Secrets
2. ✅ Commit this workflow file
3. ✅ Push to develop branch to test pipeline
4. ✅ Monitor build and test stages
5. ✅ Once verified, push to main for full deployment
