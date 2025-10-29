#!/bin/bash

set -e

echo "🚀 Creating Argo CD Applications..."

# Vérifier que nous sommes connectés à Kubernetes
echo "🔍 Checking Kubernetes connection..."
kubectl cluster-info

# Vérifier qu'Argo CD est installé
echo "🔍 Checking Argo CD installation..."
kubectl get pods -n argocd

# Créer les namespaces s'ils n'existent pas
echo "📁 Creating namespaces..."
kubectl create namespace banking-app-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace banking-app-staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace banking-app-prod --dry-run=client -o yaml | kubectl apply -f -

# Application Development
echo "🟢 Creating banking-app-dev..."
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: banking-app-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/kehe0014/hke-2025-final-banking-app-project.git
    targetRevision: develop
    path: gitops/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: banking-app-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# Application Staging
echo "🟡 Creating banking-app-staging..."
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: banking-app-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/kehe0014/hke-2025-final-banking-app-project.git
    targetRevision: develop
    path: gitops/overlays/staging
  destination:
    server: https://kubernetes.default.svc
    namespace: banking-app-staging
  syncPolicy:
    automated:
      prune: false
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# Application Production
echo "🔴 Creating banking-app-prod..."
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: banking-app-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/kehe0014/hke-2025-final-banking-app-project.git
    targetRevision: main
    path: gitops/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: banking-app-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

echo "✅ All Argo CD applications created!"
echo ""
echo "📋 Next steps:"
echo "1. Check applications in Argo CD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. Access Argo CD: https://localhost:8080"
echo "3. Default credentials: admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"