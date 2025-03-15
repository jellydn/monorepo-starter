# Kubernetes Deployment

This directory contains Kubernetes manifests and scripts to deploy the monorepo application to Kubernetes environments.

## Directory Structure

```
kubernetes/
├── base/                 # Base Kubernetes configuration
│   ├── api-deployment.yaml
│   ├── api-service.yaml
│   ├── configmap.yaml
│   ├── ingress.yaml
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── web-deployment.yaml
│   └── web-service.yaml
│
├── overlays/             # Environment-specific overlays
│   ├── local/            # Local development with kind
│   │   ├── kustomization.yaml
│   │   └── ...
│   │
│   ├── dev/              # Development environment
│   │   ├── kustomization.yaml
│   │   └── ...
│   │
│   ├── staging/          # Staging environment
│   │   ├── kustomization.yaml
│   │   └── ...
│   │
│   └── production/       # Production environment
│       ├── kustomization.yaml
│       ├── ingress-patch.yaml
│       ├── web-deployment-patch.yaml
│       ├── api-deployment-patch.yaml
│       ├── configmap-patch.yaml
│       ├── network-policy.yaml
│       ├── pod-disruption-budget.yaml
│       ├── resource-quota.yaml
│       ├── README.md
│       └── ENVIRONMENTS.md
│
└── scripts/              # Deployment and setup scripts
    ├── setup-local.sh
    ├── deploy-local.sh
    ├── deploy-production.sh
    ├── install-dashboard.sh
    ├── install-gui-tools.sh
    ├── install-k9s.sh
    └── install-lens.sh
```

## Architecture

```
                                     ┌─────────────────────────────────────────────┐
                                     │            Kubernetes Cluster               │
                                     │                                             │
                                     │  ┌─────────────┐       ┌─────────────┐     │
┌─────────────┐    ┌─────────────┐   │  │             │       │             │     │
│             │    │             │   │  │             │       │             │     │
│   Users     ├───►│  Cloudflare ├───┼─►│  Ingress    ├───────►    Web     │     │
│             │    │  (Optional) │   │  │  Controller │       │  Service   │     │
│             │    │             │   │  │             │       │             │     │
└─────────────┘    └─────────────┘   │  │             │       └──────┬──────┘     │
                                     │  │             │              │            │
                                     │  │             │              │            │
                                     │  │             │       ┌──────▼──────┐     │
                                     │  │             │       │             │     │
                                     │  │             │       │    API      │     │
                                     │  │             ├───────►  Service    │     │
                                     │  │             │       │             │     │
                                     │  └─────────────┘       └─────────────┘     │
                                     │                                             │
                                     └─────────────────────────────────────────────┘
```

## Kubernetes Templates

This repository offers two Kubernetes deployment templates:

### 1. Basic Template (For Beginners)

If you're new to Kubernetes, you can use the basic template available at [basic-k8s branch](https://github.com/jellydn/monorepo-starter/tree/basic-k8s). This template provides a simpler structure with all configuration in a single `k8s` directory.

To get started with the basic template:

```sh
# Clone the repository with the basic-k8s branch
git clone -b basic-k8s https://github.com/jellydn/monorepo-starter.git
cd monorepo-starter

# Set up a local Kubernetes cluster with kind
./k8s/setup-local.sh

# Deploy the application to the local cluster
./k8s/deploy.sh
```

### 2. Advanced Template (Current)

The current template uses a more sophisticated structure with Kustomize overlays for different environments. This approach is better suited for production deployments and multi-environment setups.

## Template Comparison (TLDR)

| Feature                 | Basic Template                    | Advanced Template                                        |
| ----------------------- | --------------------------------- | -------------------------------------------------------- |
| **Structure**           | Flat directory with all manifests | Base + overlays with environment-specific configurations |
| **Environments**        | Single environment                | Multiple environments (local, dev, staging, production)  |
| **Customization**       | Limited, requires manual edits    | Extensive, uses Kustomize patches                        |
| **Security**            | Basic                             | Advanced (network policies, security contexts)           |
| **High Availability**   | Not configured                    | Configured (pod disruption budgets, multiple replicas)   |
| **Resource Management** | Basic                             | Advanced (resource quotas, limits)                       |
| **Best For**            | Learning, simple deployments      | Production, multi-environment setups                     |

## Deployment Instructions

### Local Development

To set up a local Kubernetes environment using Kind:

```sh
# Run the setup script
./kubernetes/scripts/setup-local.sh

# Deploy to local environment
./kubernetes/scripts/deploy-local.sh
```

### Production Deployment

For production deployment:

```sh
# Deploy to production with custom settings
REGISTRY_URL=your-registry.example.com \
CONTEXT=your-production-context \
DOMAIN=next-app-demo.itman.fyi \
API_DOMAIN=express-api-demo.itman.fyi \
./kubernetes/scripts/deploy-production.sh
```

For detailed instructions on production deployment, see the [Production README](./overlays/production/README.md).

### Environment-Specific Configurations

For information on deploying to different environments (cloud providers, VMs, physical servers), see the [Environments Guide](./overlays/production/ENVIRONMENTS.md).

## Kubernetes GUI Tools

For easier management of your Kubernetes cluster, you can install various GUI tools:

```bash
./kubernetes/scripts/install-gui-tools.sh
```

This script provides a menu to install and configure the following tools:

- Kubernetes Dashboard: Web-based UI for Kubernetes
- K9s: Terminal-based UI for Kubernetes
- Lens Desktop: Standalone application for Kubernetes management

## Accessing the Application

### Local Development

- Web UI: http://demo-app.127.0.0.1.nip.io
- API: http://api-demo-app.127.0.0.1.nip.io

### Production

- Web UI: https://next-app-demo.itman.fyi
- API: https://express-api-demo.itman.fyi

## Using GitHub Container Registry (GHCR)

You can deploy the application using pre-built images from GitHub Container Registry:

```sh
# Deploy using GHCR images
USE_GHCR=true GHCR_USERNAME=your-github-username GHCR_REPO=monorepo-starter GHCR_TAG=latest ./kubernetes/scripts/deploy-local.sh
```

For more information on using GHCR, see the main [README.md](../README.md).
