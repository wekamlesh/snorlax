# Repository Structure

This directory structure is set up for a GitOps workflow using ArgoCD.

## Entry Point
- **`app-of-apps.yaml`**: The main Application that manages all other applications.
  - Points to `k8s/apps/app-of-apps`
  - Deploys to `argocd` namespace

## Application Manifests
Located in `k8s/apps/app-of-apps/`:
- **`n8n.yaml`**: ArgoCD Application for n8n
- **`observability.yaml`**: ArgoCD Application for Prometheus/Grafana
- **`uptime-kuma.yaml`**: ArgoCD Application for Uptime Kuma

## Helm Charts
Located in `k8s/apps/`:
- **`n8n/`**: Wrapper chart for n8n
- **`observability/`**: Wrapper chart for kube-prometheus-stack
- **`uptime-kuma/`**: Wrapper chart for Uptime Kuma

## Configuration
Edit the `values.yaml` in each app directory (`k8s/apps/<app>/values.yaml`).
Use `git update-index --skip-worktree <file>` to ignore local changes to these files if you want to keep secrets/domains private.
