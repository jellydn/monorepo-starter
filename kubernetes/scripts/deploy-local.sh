#!/bin/bash
set -e

# Local Deployment Script for Kubernetes
# This script deploys the application to a local Kubernetes cluster
# using the local overlay with Kustomize

# Configuration
REGISTRY_URL=${REGISTRY_URL:-"localhost:5000"}
NAMESPACE=${NAMESPACE:-"monorepo-app"}
CONTEXT=${CONTEXT:-""}
IP_ADDRESS=${IP_ADDRESS:-"127.0.0.1"}
DOMAIN=${DOMAIN:-"demo-app.$IP_ADDRESS.nip.io"}
API_DOMAIN=${API_DOMAIN:-"api-demo-app.$IP_ADDRESS.nip.io"}
API_URL=${API_URL:-"http://$API_DOMAIN"}
TIMESTAMP=$(date +%s)

# Display banner
echo "=================================================="
echo "  Local Development Deployment to Kubernetes"
echo "  Domain: $DOMAIN"
echo "  API Domain: $API_DOMAIN"
echo "=================================================="

# Display configuration
echo "Deployment Configuration:"
echo "------------------------"
echo "Registry URL: $REGISTRY_URL"
echo "Namespace: $NAMESPACE"
echo "Kubernetes Context: ${CONTEXT:-"default"}"
echo "IP Address for nip.io: $IP_ADDRESS"
echo "Web Domain: $DOMAIN"
echo "API Domain: $API_DOMAIN"
echo "API URL: $API_URL"
echo "Timestamp: $TIMESTAMP"
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

# Build Docker images locally
echo "Building Docker images locally..."
docker build -t $REGISTRY_URL/web:latest \
  -f apps/web/Dockerfile . || {
  echo "Error: Failed to build web image."
  exit 1
}

docker build -t $REGISTRY_URL/api:latest -f apps/api/Dockerfile . || {
  echo "Error: Failed to build API image."
  exit 1
}

# Push Docker images
echo "Pushing Docker images to $REGISTRY_URL..."
docker push $REGISTRY_URL/web:latest || {
  echo "Error: Failed to push web image to $REGISTRY_URL."
  echo "If using localhost:5000, make sure the local registry is running."
  echo "You can check with: docker ps | grep registry"
  exit 1
}

docker push $REGISTRY_URL/api:latest || {
  echo "Error: Failed to push API image to $REGISTRY_URL."
  echo "If using localhost:5000, make sure the local registry is running."
  echo "You can check with: docker ps | grep registry"
  exit 1
}

# Create namespace if it doesn't exist
echo "Checking for namespace: $NAMESPACE"
kubectl get namespace $NAMESPACE > /dev/null 2>&1 || {
  echo "Creating namespace: $NAMESPACE"
  kubectl apply -f kubernetes/base/namespace.yaml
}

# Create a temporary directory for modified manifests
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory for manifests: $TEMP_DIR"

# Copy all manifests to the temporary directory
cp -r kubernetes/overlays/local/*.yaml $TEMP_DIR/
cp -r kubernetes/base/*.yaml $TEMP_DIR/

# Create postgres directory and copy postgres manifests
mkdir -p $TEMP_DIR/postgres
cp -r kubernetes/base/postgres/*.yaml $TEMP_DIR/postgres/

# Update image references in deployment files
echo "Updating image references in deployment files..."
sed -i.bak "s|\${REGISTRY_URL}|$REGISTRY_URL|g" $TEMP_DIR/web-deployment.yaml
sed -i.bak "s|\${REGISTRY_URL}|$REGISTRY_URL|g" $TEMP_DIR/api-deployment.yaml
sed -i.bak "s|\${REGISTRY_URL}|$REGISTRY_URL|g" $TEMP_DIR/db-migration-job.yaml

# Update domain names in ingress
echo "Updating domain names in ingress..."
sed -i.bak "s/host: demo-app.127.0.0.1.nip.io/host: $DOMAIN/g" $TEMP_DIR/ingress.yaml
sed -i.bak "s/host: api-demo-app.127.0.0.1.nip.io/host: $API_DOMAIN/g" $TEMP_DIR/ingress.yaml

# Update API URL in web deployment
echo "Updating API URL in web deployment..."
sed -i.bak "s|\${API_URL}|$API_URL|g" $TEMP_DIR/web-deployment.yaml
sed -i.bak "s|\${TIMESTAMP}|$TIMESTAMP|g" $TEMP_DIR/web-deployment.yaml
sed -i.bak "s|\${TIMESTAMP}|$TIMESTAMP|g" $TEMP_DIR/api-deployment.yaml
sed -i.bak "s|\${TIMESTAMP}|$TIMESTAMP|g" $TEMP_DIR/db-migration-job.yaml

# Create a temporary kustomization file
cat > $TEMP_DIR/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: $NAMESPACE

resources:
  - namespace.yaml
  - web-deployment.yaml
  - web-service.yaml
  - api-deployment.yaml
  - api-service.yaml
  - ingress.yaml
  - configmap.yaml
  - autoscale.yaml
  - db-migration-job.yaml
  - postgres/

commonLabels:
  environment: local
  app.kubernetes.io/managed-by: kustomize
  app.kubernetes.io/part-of: monorepo-app

images:
  - name: \${REGISTRY_URL}/web
    newName: $REGISTRY_URL/web
    newTag: latest
  - name: \${REGISTRY_URL}/api
    newName: $REGISTRY_URL/api
    newTag: latest
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

# Check if ingress controller is ready
echo "Checking if ingress controller is ready..."
if ! kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller | grep -q Running; then
  echo "Warning: NGINX Ingress Controller might not be fully ready yet."
  echo "Check its status with: kubectl get pods -n ingress-nginx"
fi

echo "You can access the application at:"
echo "- Web: http://$DOMAIN"
echo "- API: http://$API_DOMAIN"
echo "- PostgreSQL: Available internally at postgres:5432"
echo "Note: nip.io automatically resolves these domains to $IP_ADDRESS"
echo "You can check the ingress status with: kubectl get ingress -n $NAMESPACE"

# Provide some helpful commands
echo ""
echo "Helpful commands:"
echo "----------------"
echo "Check pod status: kubectl get pods -n $NAMESPACE"
echo "Check services: kubectl get svc -n $NAMESPACE"
echo "Check ingress: kubectl get ingress -n $NAMESPACE"
echo "View logs for web: kubectl logs -n $NAMESPACE -l app=web"
echo "View logs for api: kubectl logs -n $NAMESPACE -l app=api"
echo "View logs for postgres: kubectl logs -n $NAMESPACE -l app=postgres"
echo "View migration logs: kubectl logs -n $NAMESPACE -l app=db-migration"