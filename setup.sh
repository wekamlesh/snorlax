#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installing K3s with Traefik disabled..."
curl -sfL https://get.k3s.io | sh -s - --disable traefik

echo "Installing Helm..."
# Download and install Helm using the official script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

echo "Waiting for K3s to start..."
sleep 10

echo "Generating kubeconfig.yaml for remote access..."
SERVER_IP=$(ip route get 1 | awk '{print $7; exit}')
SOURCE_CONFIG="/etc/rancher/k3s/k3s.yaml"
DEST_CONFIG="kubeconfig.yaml"

sudo cat $SOURCE_CONFIG | sed "s/127.0.0.1/$SERVER_IP/g" > $DEST_CONFIG
chmod 600 $DEST_CONFIG

echo "--------------------------------------------------"
echo "Setup Complete!"
echo "K3s Version: $(k3s --version)"
echo "Helm Version: $(helm version --short)"
echo "Server IP: $SERVER_IP"
echo "Remote kubeconfig generated at: $(pwd)/$DEST_CONFIG"
echo "--------------------------------------------------"