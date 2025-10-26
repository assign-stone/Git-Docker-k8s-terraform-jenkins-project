#!/usr/bin/env bash
set -euo pipefail

# Helper to apply k8s manifests. Expects kubectl configured (KUBECONFIG) for target cluster.
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Optionally show rollout status
kubectl rollout status deployment/flask-app --timeout=120s
kubectl get svc flask-app-svc -o wide
