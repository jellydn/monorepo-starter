# Kubernetes Overlays

This directory contains Kustomize overlays for different environments. Each overlay customizes the base Kubernetes configuration for a specific environment.

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
└── overlays/             # Environment-specific overlays
    ├── dev/              # Development environment
    ├── staging/          # Staging environment
    └── production/       # Production environment
        ├── README.md
        ├── api-deployment-patch.yaml
        ├── configmap-patch.yaml
        ├── ingress-patch.yaml
        ├── kustomization.yaml
        ├── network-policy.yaml
        ├── pod-disruption-budget.yaml
        ├── resource-quota.yaml
        └── web-deployment-patch.yaml
```

## Available Environments

### Production

The production overlay is configured for the domain `itman.fyi` with:

- Web application: `next-app-demo.itman.fyi`
- API: `express-api-demo.itman.fyi`

Key features:

- TLS/HTTPS with Let's Encrypt certificates
- Cloudflare integration
- High availability with multiple replicas
- Network policies for enhanced security
- Resource quotas and limits
- Pod disruption budgets

For detailed instructions, see the [Production README](./production/README.md).

## Deployment Instructions

### Using Kustomize Directly

To deploy using Kustomize:

```bash
# Deploy to production
kubectl apply -k kubernetes/overlays/production
```

### Using the Deployment Script

For production deployment with custom settings:

```bash
# Deploy to production
REGISTRY_URL=your-registry.example.com \
CONTEXT=your-production-context \
DOMAIN=next-app-demo.itman.fyi \
API_DOMAIN=express-api-demo.itman.fyi \
./kubernetes/scripts/deploy-production.sh
```

## Creating New Overlays

To create a new overlay for a different environment:

1. Create a new directory under `overlays/`
2. Create a `kustomization.yaml` file that references the base
3. Add patch files for any resources you want to customize
4. Add any additional resources specific to that environment

Example:

```bash
mkdir -p kubernetes/overlays/staging
cp kubernetes/overlays/production/kustomization.yaml kubernetes/overlays/staging/
# Edit the kustomization.yaml and create necessary patch files
```
