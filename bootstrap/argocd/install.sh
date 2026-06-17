#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/vimleshkpandey/platform-gitops"

echo ">>> Step 1: Creating namespaces..."
kubectl apply -f ../namespaces.yaml

echo ">>> Step 2: Installing Cilium..."
helm repo add cilium https://helm.cilium.io/ --force-update
helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --values ../cilium/values.yaml \
  --wait

echo ">>> Verifying Cilium..."
cilium status --wait

echo ">>> Step 3: Installing Istio Ambient..."
bash ../istio/install.sh

echo ">>> Step 4: Installing Sealed Secrets..."
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets --force-update
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system \
  --values ../sealed-secrets/values.yaml \
  --wait

echo ">>> Step 5: Installing ArgoCD..."
helm repo add argo https://argoproj.github.io/argo-helm --force-update
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --values values.yaml \
  --wait

echo ">>> Step 6: Handing control to ArgoCD (applying root app)..."
# Replace vimleshkpandey placeholder first
sed "s|vimleshkpandey/platform-gitops|${REPO_URL#https://github.com/}|g" ../root-app.yaml | kubectl apply -f -

echo ""
echo "Bootstrap complete!"
echo ""
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
echo ""
echo "ArgoCD is now managing the cluster. Push changes to Git to deploy."
echo "Port-forward to access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
