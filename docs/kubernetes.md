# Kubernetes Deployment

This document describes how to deploy the monorepo application to Kubernetes environments.

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
│   ├── web-service.yaml
│   ├── db-migration-job.yaml  # Database migration job
│   └── postgres/         # PostgreSQL database configuration
│       ├── postgres-deployment.yaml
│       ├── postgres-service.yaml
│       ├── postgres-configmap.yaml
│       ├── postgres-pvc.yaml
│       └── kustomization.yaml
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
│       ├── postgres-deployment-patch.yaml  # Production-specific PostgreSQL settings
│       ├── postgres-pvc-patch.yaml         # Production-specific PostgreSQL storage
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
    ├── run-migration.sh        # Script for manual database migrations
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
                                     │  │             ├───────►  Service    ├─────┼───┐
                                     │  │             │       │             │     │   │
                                     │  └─────────────┘       └─────────────┘     │   │
                                     │                                             │   │
                                     │                        ┌─────────────┐      │   │
                                     │                        │             │      │   │
                                     │                        │  PostgreSQL ◄──────┘   │
                                     │                        │  Database   │          │
                                     │                        │             │          │
                                     │                        └─────────────┘          │
                                     │                                                 │
                                     └─────────────────────────────────────────────────┘
```

## PostgreSQL Database Configuration

The application includes a PostgreSQL database for data persistence. The database is configured with the following components:

### Base Configuration (Development)

- **Deployment**: Single replica PostgreSQL 16 container with resource limits (256Mi-512Mi memory, 0.1-0.5 CPU cores)
- **Service**: Internal ClusterIP service exposing port 5432
- **ConfigMap**: Contains database credentials and configuration
- **PersistentVolumeClaim**: 1Gi storage for database files

### Production Configuration

- **Increased Resources**: Higher resource limits (512Mi-1Gi memory, 0.25-1 CPU cores)
- **Increased Storage**: 10Gi storage for database files
- **Network Policies**: Restricts database access to only the API service
- **Pod Disruption Budget**: Ensures database availability during cluster maintenance

### Connection Information

The API service connects to the database using the following connection string:

```
postgresql://postgres:postgres@postgres:5432/monorepo
```

This connection string is configured in the API deployment as an environment variable.

## Database Migrations

The application uses Prisma for database migrations. Migrations are automatically run during deployment using a Kubernetes Job.

### Migration Job

The migration job is defined in `kubernetes/base/db-migration-job.yaml` and:

1. Uses the same container image as the API service
2. Runs `npx prisma migrate deploy` to apply any pending migrations
3. Includes an init container that waits for the database to be ready
4. Has a backoff limit to retry failed migrations
5. Is automatically deleted after completion (TTL)

### Manual Migrations

For manual migrations, you can use the `run-migration.sh` script:

```sh
# Run migrations in the default namespace
./kubernetes/scripts/run-migration.sh

# Run migrations in a specific namespace
./kubernetes/scripts/run-migration.sh --namespace=custom-namespace

# Run migrations with a specific Kubernetes context
./kubernetes/scripts/run-migration.sh --context=production-cluster
```

### Deployment Order

During deployment, resources are applied in the following order:

1. Namespace and ConfigMaps
2. PostgreSQL database
3. Database migration job
4. API and Web services

The API deployment includes an annotation (`depends-on: "db-migration"`) to indicate that it should start after the migration job completes.

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
| **Database**            | Not included                      | PostgreSQL with persistent storage                       |
| **Migrations**          | Not included                      | Automated via Kubernetes Jobs                            |
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

For detailed instructions on production deployment, see the [Production README](../kubernetes/overlays/production/README.md).

### Environment-Specific Configurations

For information on deploying to different environments (cloud providers, VMs, physical servers), see the [Environments Guide](../kubernetes/overlays/production/ENVIRONMENTS.md).

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
- PostgreSQL: Available internally at `postgres:5432`

### Production

- Web UI: https://next-app-demo.itman.fyi
- API: https://express-api-demo.itman.fyi
- PostgreSQL: Available internally at `postgres:5432`

## Using GitHub Container Registry (GHCR)

You can deploy the application using pre-built images from GitHub Container Registry:

```sh
# Deploy using GHCR images
USE_GHCR=true GHCR_USERNAME=your-github-username GHCR_REPO=monorepo-starter GHCR_TAG=latest ./kubernetes/scripts/deploy-local.sh
```

For more information on using GHCR, see the main [README.md](../README.md).
