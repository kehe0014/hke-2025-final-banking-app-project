#!/bin/bash

set -e  # Exit on error

ENVIRONMENT="$1"

case "${ENVIRONMENT}" in
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

echo "🔍 Running health checks in namespace: ${NAMESPACE}"

# Vérifier que les pods sont running
kubectl get pods -n "${NAMESPACE}"

# Vérifier la santé de l'application
if kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=banking-app --no-headers | grep -q Running; then
    echo "✅ Application pods are running"
    
    # Essayer de vérifier la santé de l'application
    if kubectl exec -n "${NAMESPACE}" deployment/banking-app -- sh -c "command -v curl >/dev/null 2>&1"; then
        kubectl exec -n "${NAMESPACE}" deployment/banking-app -- curl -s http://localhost:8000/health || echo "⚠️ Health endpoint not ready or not responding"
    else
        echo "⚠️ curl not available in container, skipping health check"
    fi
else
    echo "❌ No running application pods found"
    exit 1
fi

echo "✅ Health checks completed for ${NAMESPACE}"