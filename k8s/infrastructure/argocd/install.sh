#!/bin/bash

set -e

# Load the environment variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -a
source "$SCRIPT_DIR/../../../.env"
set +a
echo "Debug: ARGOCD_DOMAIN is '${ARGOCD_DOMAIN}'"

echo "Adding Argo CD Helm Repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "Applying Namespaces..."
kubectl apply -f "${SCRIPT_DIR}/../../core/namespace.yaml"

echo "Generating Argo CD Manifest with dynamic domain..."

# We use envsubst to replace variables in values.yaml, then pipe it to helm.
# The '-' tells helm to read from stdin (piped input).
envsubst < "${SCRIPT_DIR}/values.yaml" > "${SCRIPT_DIR}/debug-values.yaml"

helm template argocd argo/argo-cd \
  --namespace argocd \
  -f "${SCRIPT_DIR}/debug-values.yaml" \
  --set "global.domain=${ARGOCD_DOMAIN}" \
  --set "server.ingress.hosts[0]=${ARGOCD_DOMAIN}" \
  --set "server.ingress.tls[0].hosts[0]=${ARGOCD_DOMAIN}" \
  --set "server.ingress.tls[0].secretName=argocd-server-tls" \
  > "${SCRIPT_DIR}/generated-manifest.yaml"

echo "Applying Argo CD Manifest..."
kubectl apply --server-side --force-conflicts -f "${SCRIPT_DIR}/generated-manifest.yaml"

echo "Waiting for Argo CD Server to be ready..."
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=300s

echo "Argo CD installed successfully!"
echo "Access it at: https://${ARGOCD_DOMAIN}"
echo "To get the initial admin password, run:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo"