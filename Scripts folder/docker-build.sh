#!/bin/bash

set -e

echo "Building frontend image..."

docker build \
    -t front-backend-frontend:latest \
    -f docker/frontend/Dockerfile .

echo "Building backend image..."

docker build \
    -t front-backend-backend:latest \
    -f docker/backend/Dockerfile .

echo "Docker build completed."
