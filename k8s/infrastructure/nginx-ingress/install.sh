#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Adding NGINX Helm Repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo "Applying Namespaces..."
kubectl apply -f "${SCRIPT_DIR}/../../core/namespace.yaml"

echo "Generating NGINX Manifest from values.yaml..."
# We use 'helm template' to generate a static YAML file.
# This allows us to commit the exact state of the system to Git.
helm template ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  -f "${SCRIPT_DIR}/values.yaml" \
  > "${SCRIPT_DIR}/generated-manifest.yaml"

echo "Applying NGINX Manifest..."
kubectl apply -f "${SCRIPT_DIR}/generated-manifest.yaml"

echo "Waiting for NGINX to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "NGINX Ingress Controller installed successfully!"