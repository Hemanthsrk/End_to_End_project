#!/bin/bash

set -e

AWS_REGION="ap-south-1"

EKS_CLUSTER_NAME="front-backend-cluster"

NAMESPACE="front-backend"


echo "Configuring EKS..."

aws eks update-kubeconfig \
    --region "${AWS_REGION}" \
    --name "${EKS_CLUSTER_NAME}"


echo "Applying namespace..."

kubectl apply \
    -f k8s/namespace.yaml


echo "Applying backend..."

kubectl apply \
    -f k8s/backend/configmap.yaml

kubectl apply \
    -f k8s/backend/secret.yaml

kubectl apply \
    -f k8s/backend/deployment.yaml

kubectl apply \
    -f k8s/backend/service.yaml


echo "Applying frontend..."

kubectl apply \
    -f k8s/frontend/deployment.yaml

kubectl apply \
    -f k8s/frontend/service.yaml


echo "Applying ingress..."

kubectl apply \
    -f k8s/ingress.yaml


echo "Checking pods..."

kubectl get pods \
    -n "${NAMESPACE}"


echo "Deployment completed."
