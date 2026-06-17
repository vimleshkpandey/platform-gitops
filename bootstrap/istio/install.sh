#!/usr/bin/env bash
set -euo pipefail

ISTIO_VERSION="1.22.0"

echo ">>> Downloading Istio ${ISTIO_VERSION}..."
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
export PATH="$PWD/istio-${ISTIO_VERSION}/bin:$PATH"

echo ">>> Installing Istio in Ambient mode..."
istioctl install \
  --set profile=ambient \
  --set meshConfig.accessLogFile=/dev/stdout \
  -y

echo ">>> Waiting for Istio pods to be ready..."
kubectl rollout status deployment/istiod -n istio-system --timeout=120s

echo ">>> Deploying waypoint proxy for applications namespace..."
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: waypoint
  namespace: applications
  annotations:
    istio.io/service-account: waypoint
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF

echo ">>> Verifying Istio installation..."
istioctl verify-install

echo ""
echo "Istio Ambient installed successfully."
echo "mTLS is active for namespaces labeled: istio.io/dataplane-mode=ambient"
