#!/bin/bash
set -e

# Production Deployment Script for Kubernetes
# This script deploys the application to a production Kubernetes cluster
# using the production overlay with Kustomize

# Default configuration
REGISTRY_URL=${REGISTRY_URL:-"ghcr.io/your-username/monorepo-starter"}
CONTEXT=${CONTEXT:-""}
DOMAIN=${DOMAIN:-"next-app-demo.itman.fyi"}
API_DOMAIN=${API_DOMAIN:-"express-api-demo.itman.fyi"}
USE_CLOUDFLARE=${USE_CLOUDFLARE:-"true"}
NAMESPACE=${NAMESPACE:-"monorepo-app"}
GHCR_TAG=${GHCR_TAG:-"latest"}

# Display banner
echo "=================================================="
echo "  Production Deployment to Kubernetes"
echo "  Domain: $DOMAIN"
echo "  API Domain: $API_DOMAIN"
echo "=================================================="

# Display configuration
echo "Deployment Configuration:"
echo "------------------------"
echo "Registry URL: $REGISTRY_URL"
echo "Kubernetes Context: ${CONTEXT:-"default"}"
echo "Namespace: $NAMESPACE"
echo "Using Cloudflare: $USE_CLOUDFLARE"
echo "Image Tag: $GHCR_TAG"
echo "------------------------"

# Set Kubernetes context if provided
if [ -n "$CONTEXT" ]; then
  echo "Setting Kubernetes context to: $CONTEXT"
  kubectl config use-context $CONTEXT
fi

# Check if kubectl is available and configured
if ! kubectl cluster-info &> /dev/null; then
  echo "Error: kubectl is not configured or cannot connect to a cluster."
  echo "Please check your Kubernetes configuration."
  exit 1
fi

# Check if the namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
  echo "Creating namespace: $NAMESPACE"
  kubectl create namespace $NAMESPACE
fi

# Pull the latest images
echo "Pulling the latest images from registry..."
docker pull $REGISTRY_URL/web:$GHCR_TAG || {
  echo "Error: Failed to pull web image from registry."
  exit 1
}

docker pull $REGISTRY_URL/api:$GHCR_TAG || {
  echo "Error: Failed to pull API image from registry."
  exit 1
}

# Create a temporary directory for modified manifests
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory for manifests: $TEMP_DIR"

# Copy all manifests to the temporary directory
cp -r kubernetes/overlays/production/*.yaml $TEMP_DIR/

# Update domain names in ingress patch
echo "Updating domain names in ingress patch..."
sed -i.bak "s/next-app-demo.itman.fyi/$DOMAIN/g" $TEMP_DIR/ingress-patch.yaml
sed -i.bak "s/express-api-demo.itman.fyi/$API_DOMAIN/g" $TEMP_DIR/ingress-patch.yaml

# Update API URL in web deployment patch
echo "Updating API URL in web deployment patch..."
sed -i.bak "s|https://express-api-demo.itman.fyi|https://$API_DOMAIN|g" $TEMP_DIR/web-deployment-patch.yaml

# Update WEB URL in API deployment patch
echo "Updating WEB URL in API deployment patch..."
sed -i.bak "s|https://next-app-demo.itman.fyi|https://$DOMAIN|g" $TEMP_DIR/api-deployment-patch.yaml

# Update URLs in configmap patch
echo "Updating URLs in configmap patch..."
sed -i.bak "s|https://express-api-demo.itman.fyi|https://$API_DOMAIN|g" $TEMP_DIR/configmap-patch.yaml
sed -i.bak "s|https://next-app-demo.itman.fyi|https://$DOMAIN|g" $TEMP_DIR/configmap-patch.yaml

# Create a temporary kustomization file
cat > $TEMP_DIR/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: $NAMESPACE

resources:
  - network-policy.yaml
  - pod-disruption-budget.yaml
  - resource-quota.yaml
  - ../../kubernetes/base

patchesStrategicMerge:
  - ingress-patch.yaml
  - web-deployment-patch.yaml
  - api-deployment-patch.yaml
  - configmap-patch.yaml

images:
  - name: \${REGISTRY_URL}/web
    newName: $REGISTRY_URL/web
    newTag: $GHCR_TAG
  - name: \${REGISTRY_URL}/api
    newName: $REGISTRY_URL/api
    newTag: $GHCR_TAG

commonLabels:
  environment: production
  app.kubernetes.io/managed-by: kustomize
  app.kubernetes.io/part-of: monorepo-app
EOF

# Apply Kubernetes manifests using kustomize
echo "Deploying to Kubernetes..."
kubectl apply -k $TEMP_DIR/ || {
  echo "Error: Failed to apply Kubernetes manifests."
  echo "Deployment files are available at: $TEMP_DIR"
  echo "You can manually apply them with: kubectl apply -k $TEMP_DIR/"
  exit 1
}

# Clean up temporary directory
rm -rf $TEMP_DIR
echo "Cleaned up temporary manifests"

echo "Deployment completed successfully!"

# Check deployment status
echo "Checking deployment status..."
kubectl rollout status deployment/web -n $NAMESPACE
kubectl rollout status deployment/api -n $NAMESPACE

if [ "$USE_CLOUDFLARE" = "true" ]; then
  echo "You can access the application at:"
  echo "- Web: https://$DOMAIN"
  echo "- API: https://$API_DOMAIN"
  echo "Note: Make sure your Cloudflare DNS is configured correctly to point to your cluster's external IP"
else
  echo "You can access the application at:"
  echo "- Web: http://$DOMAIN"
  echo "- API: http://$API_DOMAIN"
fi

# Provide some helpful commands
echo ""
echo "Helpful commands:"
echo "----------------"
echo "Check pod status: kubectl get pods -n $NAMESPACE"
echo "Check services: kubectl get svc -n $NAMESPACE"
echo "Check ingress: kubectl get ingress -n $NAMESPACE"
echo "View logs for web: kubectl logs -n $NAMESPACE -l app=web"
echo "View logs for api: kubectl logs -n $NAMESPACE -l app=api"
echo "Scale deployments: kubectl scale deployment/web -n $NAMESPACE --replicas=5"