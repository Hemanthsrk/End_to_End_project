#!/bin/bash

set -e

AWS_REGION="ap-south-1"

AWS_ACCOUNT_ID="YOUR_AWS_ACCOUNT_ID"

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

FRONTEND_REPO="front-backend-frontend"

BACKEND_REPO="front-backend-backend"

IMAGE_TAG="${1:-latest}"


echo "Logging into ECR..."

aws ecr get-login-password \
    --region "${AWS_REGION}" |
docker login \
    --username AWS \
    --password-stdin "${ECR_REGISTRY}"


echo "Tagging frontend..."

docker tag \
    front-backend-frontend:latest \
    "${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}"


echo "Tagging backend..."

docker tag \
    front-backend-backend:latest \
    "${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}"


echo "Pushing frontend..."

docker push \
    "${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}"


echo "Pushing backend..."

docker push \
    "${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}"


echo "ECR push completed."
