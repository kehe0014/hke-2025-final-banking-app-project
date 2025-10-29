#!/bin/bash

ENVIRONMENT=$1

case $ENVIRONMENT in
    "production")
        NAMESPACE="banking-app-prod"
        ;;
    "staging")
        NAMESPACE="banking-app-staging"
        ;;
    *)
        NAMESPACE="banking-app-dev"
        ;;
esac

echo "🔍 Running health checks in namespace: $NAMESPACE"

# Vérifier que les pods sont running
kubectl get pods -n $NAMESPACE

# Vérifier la santé de l'application
kubectl exec -n $NAMESPACE deployment/banking-app -- curl -s http://localhost:8000/health || echo "Health endpoint not ready"

echo "✅ Health checks completed for $NAMESPACE"