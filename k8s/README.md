# Kubernetes Deployment

This directory contains Kubernetes manifests and scripts to deploy the monorepo application to Kubernetes.

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

## Directory Structure

```
k8s/
├── api-deployment.yaml     # API deployment configuration
├── api-service.yaml        # API service configuration
├── configmap.yaml          # ConfigMap for environment variables
├── deploy.sh               # Deployment script
├── ingress.yaml            # Ingress configuration for external access
├── install-dashboard.sh    # Script to install Kubernetes Dashboard
├── install-gui-tools.sh    # Main script to install GUI tools
├── install-k9s.sh          # Script to install K9s
├── install-lens.sh         # Script to install Lens Desktop
├── kustomization.yaml      # Kustomize configuration
├── namespace.yaml          # Namespace definition
├── setup-local.sh          # Script to set up local Kubernetes environment
├── web-deployment.yaml     # Web deployment configuration
└── web-service.yaml        # Web service configuration
```

## Local Development

To set up a local Kubernetes environment using kind (Kubernetes in Docker):

```bash
./k8s/setup-local.sh
```

This script will:

1. Create a local Docker registry
2. Create a kind cluster
3. Install NGINX Ingress Controller
4. Configure the cluster to work with the local registry
5. Add `app.local` to your `/etc/hosts` file

## Deployment

### Local Deployment

For local development (without Cloudflare):

```bash
REGISTRY_URL=localhost:5000 ./k8s/deploy.sh
```

### Production Deployment with Cloudflare

For production deployment with Cloudflare as a proxy:

1. Set up DNS in Cloudflare pointing to your Kubernetes cluster's external IP
2. Configure Cloudflare SSL/TLS settings (recommended: Full or Full (strict))
3. Deploy your application:

```bash
REGISTRY_URL=your-registry.example.com CONTEXT=your-cluster-context ./k8s/deploy.sh
```

4. Update the ingress configuration to work with Cloudflare (see Cloudflare Integration section)

The deployment script will:

1. Build Docker images for the web and API services
2. Push the images to the specified registry
3. Apply the Kubernetes manifests using kustomize

## Kubernetes GUI Tools

For easier management of your Kubernetes cluster, you can install various GUI tools:

```bash
./k8s/install-gui-tools.sh
```

This script provides a menu to install and configure the following tools:

### 1. Kubernetes Dashboard

A web-based UI for Kubernetes that allows you to:

- Deploy containerized applications
- Troubleshoot your applications
- Manage cluster resources
- View logs and metrics

To install only the Kubernetes Dashboard:

```bash
./k8s/install-dashboard.sh
```

### 2. K9s

A terminal-based UI for Kubernetes that provides:

- Real-time monitoring of your cluster
- Resource management
- Log viewing
- Command execution in pods

To install only K9s:

```bash
./k8s/install-k9s.sh
```

### 3. Lens Desktop

A standalone application that provides:

- Multi-cluster management
- Real-time statistics
- Built-in terminal
- Resource editing and management
- Integrated debugging tools

To install only Lens Desktop:

```bash
./k8s/install-lens.sh
```

## Cloudflare Integration

When using Cloudflare as a proxy in front of your Kubernetes cluster, consider the following:

### DNS Configuration

1. Add an A record in Cloudflare DNS pointing to your Kubernetes cluster's external IP
2. Ensure the proxy status is enabled (orange cloud icon)

### SSL/TLS Configuration

1. Set SSL/TLS encryption mode to "Full" or "Full (strict)" in Cloudflare dashboard
2. If using "Full (strict)", you'll need to configure TLS certificates in your Kubernetes cluster

### Security Features

Cloudflare provides additional security features you can enable:

- Web Application Firewall (WAF)
- DDoS protection
- Rate limiting
- Bot management

### Performance Optimization

- Enable Cloudflare caching for static assets
- Use Cloudflare Workers for edge computing capabilities
- Enable Brotli compression

## Accessing the Application

### Local Development

- Web UI: http://app.local
- API: http://app.local/api

### Production with Cloudflare

- Web UI: https://yourdomain.com
- API: https://yourdomain.com/api

## Configuration

You can customize the deployment by modifying the following files:

- `configmap.yaml`: Environment variables
- `web-deployment.yaml` and `api-deployment.yaml`: Resource limits, replicas, etc.
- `ingress.yaml`: Hostname and path configuration

## Scaling

To scale the application, you can modify the `replicas` field in the deployment files or use the `kubectl scale` command:

```bash
kubectl scale deployment web --replicas=3 -n monorepo-app
kubectl scale deployment api --replicas=3 -n monorepo-app
```

## Cleanup

To delete the application from Kubernetes:

```bash
kubectl delete -k k8s/
```

To delete the local kind cluster:

```bash
kind delete cluster --name monorepo-cluster
```
