#!/bin/bash

set -e

# Load the environment variables from the .env file
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -a
source "$SCRIPT_DIR/../../../.env"
set +a

echo "Adding Jetstack (Cert-Manager) Helm Repository..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

echo "Applying Namespaces..."
kubectl apply -f "${SCRIPT_DIR}/../../core/namespace.yaml"

echo "Generating Cert-Manager Manifest..."
helm template cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  -f "${SCRIPT_DIR}/values.yaml" \
  > "${SCRIPT_DIR}/generated-manifest.yaml"

echo "Applying Cert-Manager Manifest..."
kubectl apply -f "${SCRIPT_DIR}/generated-manifest.yaml"

echo "Waiting for Cert-Manager Webhook to be ready..."
# We wait for the webhook specifically because the ClusterIssuer needs it
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=webhook \
  --timeout=120s

echo "Applying Cluster Issuer..."
# We use 'envsubst' to inject the email variable into the yaml before applying
envsubst < "${SCRIPT_DIR}/cluster-issuer.yaml" | kubectl apply -f -

echo "Cert-Manager installed successfully!"