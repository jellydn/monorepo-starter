# Production Kubernetes Configuration

This directory contains Kubernetes configuration overlays for the production environment using Kustomize.

## Domain Configuration

- **Domain**: `itman.fyi`
- **Web Application**: `next-app-demo.itman.fyi`
- **API**: `express-api-demo.itman.fyi`

## Files Overview

- **kustomization.yaml**: Main configuration file for Kustomize
- **ingress-patch.yaml**: Configures production domains and TLS
- **web-deployment-patch.yaml**: Production settings for web application
- **api-deployment-patch.yaml**: Production settings for API application
- **configmap-patch.yaml**: Production environment variables
- **network-policy.yaml**: Network security policies
- **pod-disruption-budget.yaml**: High availability settings
- **resource-quota.yaml**: Resource usage limits

## Deployment Instructions

### Prerequisites

1. A Kubernetes cluster (AKS, GKE, EKS, or self-managed)
2. `kubectl` configured to access your cluster
3. `kustomize` installed (or use `kubectl` with built-in kustomize)
4. Container registry with your application images

### Deployment Steps

1. **Set up DNS**:

   - Configure DNS records for `next-app-demo.itman.fyi` and `express-api-demo.itman.fyi`
   - If using Cloudflare, ensure proxy is enabled

2. **Install cert-manager** (if not already installed):

   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
   ```

3. **Create a ClusterIssuer for Let's Encrypt**:

   ```bash
   kubectl apply -f - <<EOF
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: letsencrypt-prod
   spec:
     acme:
       server: https://acme-v02.api.letsencrypt.org/directory
       email: your-email@itman.fyi
       privateKeySecretRef:
         name: letsencrypt-prod
       solvers:
       - http01:
           ingress:
             class: nginx
   EOF
   ```

4. **Deploy using kustomize**:

   ```bash
   kubectl apply -k kubernetes/overlays/production
   ```

   Or using the deploy script:

   ```bash
   REGISTRY_URL=your-registry.example.com \
   CONTEXT=your-production-context \
   USE_CLOUDFLARE=true \
   DOMAIN=next-app-demo.itman.fyi \
   API_DOMAIN=express-api-demo.itman.fyi \
   ./k8s/deploy.sh
   ```

5. **Verify deployment**:
   ```bash
   kubectl get pods,svc,ingress -n monorepo-app
   ```

## Environment Variables

| Variable             | Production Value                   | Description                          |
| -------------------- | ---------------------------------- | ------------------------------------ |
| NODE_ENV             | production                         | Node.js environment                  |
| API_URL              | https://express-api-demo.itman.fyi | URL for the API service              |
| WEB_URL              | https://next-app-demo.itman.fyi    | URL for the web service              |
| LOG_LEVEL            | info                               | Logging level                        |
| ENABLE_COMPRESSION   | true                               | Enable response compression          |
| ENABLE_CACHE         | true                               | Enable caching                       |
| CACHE_TTL            | 3600                               | Cache time-to-live in seconds        |
| CORS_ORIGIN          | https://next-app-demo.itman.fyi    | Allowed CORS origin                  |
| RATE_LIMIT_WINDOW_MS | 60000                              | Rate limiting window in milliseconds |
| RATE_LIMIT_MAX       | 100                                | Maximum requests per window          |

## Security Features

- **TLS**: All traffic is encrypted using Let's Encrypt certificates
- **Network Policies**: Strict network policies limit pod-to-pod communication
- **Security Contexts**: Containers run as non-root with restricted capabilities
- **Resource Limits**: Prevents resource exhaustion attacks

## Monitoring and Observability

The deployment is configured with annotations for Prometheus scraping:

- Web metrics: `https://next-app-demo.itman.fyi/metrics`
- API metrics: `https://express-api-demo.itman.fyi/metrics`

## Scaling

- **Horizontal Pod Autoscaler**: Automatically scales based on CPU usage
- **Pod Disruption Budget**: Ensures high availability during maintenance

## Troubleshooting

- **Check pod status**:

  ```bash
  kubectl get pods -n monorepo-app
  ```

- **View pod logs**:

  ```bash
  kubectl logs -n monorepo-app -l app=web
  kubectl logs -n monorepo-app -l app=api
  ```

- **Check ingress status**:

  ```bash
  kubectl get ingress -n monorepo-app
  ```

- **Verify TLS certificates**:
  ```bash
  kubectl get certificates,certificaterequests -n monorepo-app
  ```
