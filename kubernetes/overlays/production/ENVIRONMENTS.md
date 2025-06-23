# Production Kubernetes Environments

This document outlines the specific configurations and considerations for deploying to different production Kubernetes environments.

## Common Configuration

Regardless of the environment, the following configurations are applied:

- Domain: `next-app-demo.itman.fyi` (Web) and `express-api-demo.itman.fyi` (API)
- TLS/HTTPS with Let's Encrypt certificates
- High availability with multiple replicas
- Network policies for enhanced security
- Resource quotas and limits
- Pod disruption budgets

## Cloud Providers

### Azure Kubernetes Service (AKS)

#### Prerequisites

1. An AKS cluster with at least 3 nodes
2. Azure Container Registry (ACR) for storing images
3. Azure DNS or Cloudflare for DNS management

#### Specific Configuration

```bash
# Deploy to AKS
REGISTRY_URL=yourregistry.azurecr.io \
CONTEXT=your-aks-context \
DOMAIN=next-app-demo.itman.fyi \
API_DOMAIN=express-api-demo.itman.fyi \
./k8s/deploy-production.sh
```

#### Additional Azure-Specific Resources

Create a file `k8s/overlays/production/azure-specific.yaml`:

```yaml
# Azure-specific annotations for the ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
    appgw.ingress.kubernetes.io/connection-draining: "true"
    appgw.ingress.kubernetes.io/connection-draining-timeout: "30"
---
# Azure Pod Identity for accessing Azure resources
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentity
metadata:
  name: monorepo-app-identity
  namespace: monorepo-app
spec:
  type: 0
  resourceID: /subscriptions/<subscription-id>/resourcegroups/<resource-group>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<identity-name>
  clientID: <client-id>
---
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentityBinding
metadata:
  name: monorepo-app-identity-binding
  namespace: monorepo-app
spec:
  azureIdentity: monorepo-app-identity
  selector: monorepo-app-identity
```

Add this file to your kustomization.yaml:

```yaml
resources:
  - ../../base
  - network-policy.yaml
  - pod-disruption-budget.yaml
  - resource-quota.yaml
  - azure-specific.yaml # Add this line
```

### Google Kubernetes Engine (GKE)

#### Prerequisites

1. A GKE cluster with at least 3 nodes
2. Google Container Registry (GCR) or Artifact Registry for storing images
3. Cloud DNS or Cloudflare for DNS management

#### Specific Configuration

```bash
# Deploy to GKE
REGISTRY_URL=gcr.io/your-project-id \
CONTEXT=gke_your-project-id_us-central1-a_your-cluster \
DOMAIN=next-app-demo.itman.fyi \
API_DOMAIN=express-api-demo.itman.fyi \
./k8s/deploy-production.sh
```

#### Additional GCP-Specific Resources

Create a file `k8s/overlays/production/gcp-specific.yaml`:

```yaml
# GCP-specific annotations for the ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "monorepo-app-ip"
    networking.gke.io/managed-certificates: "monorepo-app-cert"
    kubernetes.io/ingress.class: "gce"
---
# GCP Managed Certificate
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: monorepo-app-cert
  namespace: monorepo-app
spec:
  domains:
    - next-app-demo.itman.fyi
    - express-api-demo.itman.fyi
---
# Workload Identity for accessing GCP resources
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monorepo-app-sa
  namespace: monorepo-app
  annotations:
    iam.gke.io/gcp-service-account: monorepo-app@your-project-id.iam.gserviceaccount.com
```

Add this file to your kustomization.yaml:

```yaml
resources:
  - ../../base
  - network-policy.yaml
  - pod-disruption-budget.yaml
  - resource-quota.yaml
  - gcp-specific.yaml # Add this line
```

## VM/VPS Environments

### Self-Managed Kubernetes on VMs

#### Prerequisites

1. A Kubernetes cluster with at least 3 nodes (1 master, 2+ workers)
2. A private Docker registry or public registry (Docker Hub, GHCR)
3. DNS management (Cloudflare recommended)
4. MetalLB or similar for load balancing

#### Specific Configuration

```bash
# Deploy to self-managed Kubernetes on VMs
REGISTRY_URL=your-registry.example.com \
CONTEXT=kubernetes-admin@kubernetes \
DOMAIN=next-app-demo.itman.fyi \
API_DOMAIN=express-api-demo.itman.fyi \
./k8s/deploy-production.sh
```

#### Additional VM-Specific Resources

Create a file `k8s/overlays/production/metallb-config.yaml`:

```yaml
# MetalLB configuration for load balancing
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.240-192.168.1.250 # Adjust to your network range
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
    - first-pool
```

This needs to be applied separately:

```bash
kubectl apply -f k8s/overlays/production/metallb-config.yaml
```

## Physical Server Environments

### Bare Metal Kubernetes

#### Prerequisites

1. A Kubernetes cluster with at least 3 physical servers
2. A private Docker registry or public registry
3. DNS management (Cloudflare recommended)
4. MetalLB or similar for load balancing
5. Storage solution (NFS, Ceph, etc.)

#### Specific Configuration

```bash
# Deploy to bare metal Kubernetes
REGISTRY_URL=your-registry.example.com \
CONTEXT=kubernetes-admin@kubernetes \
DOMAIN=next-app-demo.itman.fyi \
API_DOMAIN=express-api-demo.itman.fyi \
./k8s/deploy-production.sh
```

#### Additional Bare Metal-Specific Resources

Create a file `k8s/overlays/production/storage-class.yaml`:

```yaml
# Storage class for NFS
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
parameters:
  server: nfs-server.example.com # Your NFS server
  path: /exported/path # Export path
  readOnly: "false"
---
# Default storage class annotation
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
```

Add this file to your kustomization.yaml:

```yaml
resources:
  - ../../base
  - network-policy.yaml
  - pod-disruption-budget.yaml
  - resource-quota.yaml
  - storage-class.yaml # Add this line
```

## Environment-Specific Considerations

### Resource Allocation

Adjust resource requests and limits based on your environment:

| Environment    | CPU Requests | Memory Requests | CPU Limits | Memory Limits |
| -------------- | ------------ | --------------- | ---------- | ------------- |
| Cloud (Small)  | 0.25 CPU     | 256Mi           | 0.5 CPU    | 512Mi         |
| Cloud (Medium) | 0.5 CPU      | 512Mi           | 1 CPU      | 1Gi           |
| Cloud (Large)  | 1 CPU        | 1Gi             | 2 CPU      | 2Gi           |
| VM/VPS         | 0.5 CPU      | 512Mi           | 1 CPU      | 1Gi           |
| Bare Metal     | 1 CPU        | 1Gi             | 2 CPU      | 2Gi           |

### Networking

Different environments may require different networking configurations:

| Environment | Ingress Controller        | Service Type | External Access     |
| ----------- | ------------------------- | ------------ | ------------------- |
| AKS         | Azure Application Gateway | ClusterIP    | Application Gateway |
| GKE         | GCE Ingress Controller    | ClusterIP    | GCP Load Balancer   |
| VM/VPS      | NGINX Ingress             | ClusterIP    | MetalLB + NGINX     |
| Bare Metal  | NGINX Ingress             | ClusterIP    | MetalLB + NGINX     |

### Storage

Different environments have different storage options:

| Environment | Storage Solution            | Provisioner              |
| ----------- | --------------------------- | ------------------------ |
| AKS         | Azure Disk/File             | kubernetes.io/azure-disk |
| GKE         | Persistent Disk             | kubernetes.io/gce-pd     |
| VM/VPS      | Local storage or NFS        | Various                  |
| Bare Metal  | NFS, Ceph, or local storage | Various                  |

## Migration Between Environments

When migrating between environments:

1. **Backup your data**:

   ```bash
   kubectl get all -n monorepo-app -o yaml > monorepo-app-backup.yaml
   ```

2. **Update your container registry**:
   - Push images to the new registry
   - Update the REGISTRY_URL in your deployment

3. **Update your Kubernetes context**:

   ```bash
   kubectl config use-context new-cluster-context
   ```

4. **Apply environment-specific configurations**:
   - Add any cloud-specific resources
   - Update storage classes if needed

5. **Deploy to the new environment**:

   ```bash
   REGISTRY_URL=new-registry \
   CONTEXT=new-context \
   ./k8s/deploy-production.sh
   ```

6. **Verify the deployment**:

   ```bash
   kubectl get pods,svc,ingress -n monorepo-app
   ```

7. **Update DNS records** to point to the new environment's IP address
