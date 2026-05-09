cd /home/charles/my-projects/Damolak-technologies/terraform
#!/bin/bash

REGION="us-east-1"
ACCOUNT="489270049918"
REPO="devops-static"
IMAGE="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$REPO:latest"

echo "Logging into ECR..."
aws ecr get-login-password --region $REGION \
| docker login --username AWS \
--password-stdin $ACCOUNT.dkr.ecr.$REGION.amazonaws.com

echo "Building image..."
docker build -f docker/Dockerfile -t $REPO .

echo "Tagging image..."
docker tag $REPO:latest $IMAGE

echo "Pushing image..."
docker push $IMAGE

echo "Deploying to ECS..."
aws ecs update-service \
  --cluster devops-cluster \
  --service devops-service \
  --force-new-deployment

echo "Done 🚀"
