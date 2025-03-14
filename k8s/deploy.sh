#!/bin/bash
set -e

# Configuration
REGISTRY_URL=${REGISTRY_URL:-"localhost:5000"}
NAMESPACE=${NAMESPACE:-"monorepo-app"}
CONTEXT=${CONTEXT:-""}
USE_CLOUDFLARE=${USE_CLOUDFLARE:-"false"}
IP_ADDRESS=${IP_ADDRESS:-"127.0.0.1"}
DOMAIN=${DOMAIN:-"demo-app.$IP_ADDRESS.nip.io"}
API_DOMAIN=${API_DOMAIN:-"api-demo-app.$IP_ADDRESS.nip.io"}
API_URL=${API_URL:-"http://$API_DOMAIN"}
TIMESTAMP=$(date +%s)
USE_GHCR=${USE_GHCR:-"false"}
GHCR_USERNAME=${GHCR_USERNAME:-"jellydn"}
GHCR_REPO=${GHCR_REPO:-"monorepo-starter"}
GHCR_TAG=${GHCR_TAG:-"latest"}

# Display configuration
echo "Deployment Configuration:"
echo "------------------------"
echo "Registry URL: $REGISTRY_URL"
echo "Namespace: $NAMESPACE"
echo "Kubernetes Context: ${CONTEXT:-"default"}"
echo "Using Cloudflare: $USE_CLOUDFLARE"
echo "IP Address for nip.io: $IP_ADDRESS"
echo "Web Domain: $DOMAIN"
echo "API Domain: $API_DOMAIN"
echo "API URL: $API_URL"
echo "Using GHCR: $USE_GHCR"
if [ "$USE_GHCR" = "true" ]; then
  echo "GHCR Username: $GHCR_USERNAME"
  echo "GHCR Repository: $GHCR_REPO"
  echo "GHCR Tag: $GHCR_TAG"
fi
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

# Build or pull Docker images
if [ "$USE_GHCR" = "true" ]; then
  if [ -z "$GHCR_USERNAME" ]; then
    echo "Error: GHCR_USERNAME is required when USE_GHCR is true."
    exit 1
  fi

  echo "Using pre-built images from GitHub Container Registry..."
  WEB_IMAGE="ghcr.io/$GHCR_USERNAME/$GHCR_REPO-web:$GHCR_TAG"
  API_IMAGE="ghcr.io/$GHCR_USERNAME/$GHCR_REPO-api:$GHCR_TAG"

  # Pull images from GHCR
  echo "Pulling web image: $WEB_IMAGE"
  if ! docker pull $WEB_IMAGE; then
    echo "Error: Failed to pull web image from GHCR."
    echo "This could be due to:"
    echo "1. The image doesn't exist with the specified tag: $GHCR_TAG"
    echo "2. The image exists but doesn't support your architecture ($(uname -m))"
    echo "3. You don't have permission to access the image"
    echo ""
    echo "Suggestions:"
    echo "- Check if the image exists: https://github.com/$GHCR_USERNAME/$GHCR_REPO/pkgs/container/$GHCR_REPO-web"
    echo "- Try a different tag (e.g., 'latest', 'main', or a specific version)"
    echo "- Build the image locally instead by running without USE_GHCR=true"
    echo "- If you're using Apple Silicon (M1/M2/M3), make sure the image supports arm64 architecture"
    echo ""
    read -p "Would you like to build the images locally instead? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Switching to local build mode..."
      USE_GHCR="false"
      # Continue to the local build section
    else
      exit 1
    fi
  fi

  if [ "$USE_GHCR" = "true" ]; then
    echo "Pulling API image: $API_IMAGE"
    if ! docker pull $API_IMAGE; then
      echo "Error: Failed to pull API image from GHCR."
      echo "This could be due to:"
      echo "1. The image doesn't exist with the specified tag: $GHCR_TAG"
      echo "2. The image exists but doesn't support your architecture ($(uname -m))"
      echo "3. You don't have permission to access the image"
      echo ""
      echo "Suggestions:"
      echo "- Check if the image exists: https://github.com/$GHCR_USERNAME/$GHCR_REPO/pkgs/container/$GHCR_REPO-api"
      echo "- Try a different tag (e.g., 'latest', 'main', or a specific version)"
      echo "- Build the image locally instead by running without USE_GHCR=true"
      echo "- If you're using Apple Silicon (M1/M2/M3), make sure the image supports arm64 architecture"
      echo ""
      read -p "Would you like to build the images locally instead? (y/n) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Switching to local build mode..."
        USE_GHCR="false"
        # Continue to the local build section
      else
        exit 1
      fi
    fi
  fi

  if [ "$USE_GHCR" = "true" ]; then
    # Tag images for local registry if needed
    echo "Tagging images for local registry..."
    docker tag $WEB_IMAGE $REGISTRY_URL/web:latest
    docker tag $API_IMAGE $REGISTRY_URL/api:latest
  fi
fi

if [ "$USE_GHCR" = "false" ]; then
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
fi

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
  kubectl create -f k8s/namespace.yaml
}

# Create a temporary directory for modified manifests
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory for manifests: $TEMP_DIR"

# Copy all manifests to the temporary directory
cp -r k8s/*.yaml $TEMP_DIR/

# Update image references in deployment files
echo "Updating image references in deployment files..."
sed -i.bak "s|\${REGISTRY_URL}|$REGISTRY_URL|g" $TEMP_DIR/web-deployment.yaml
sed -i.bak "s|\${REGISTRY_URL}|$REGISTRY_URL|g" $TEMP_DIR/api-deployment.yaml

# Update domain names in ingress
echo "Updating domain names in ingress..."
sed -i.bak "s/host: demo-app.127.0.0.1.nip.io/host: $DOMAIN/g" $TEMP_DIR/ingress.yaml
sed -i.bak "s/host: api-demo-app.127.0.0.1.nip.io/host: $API_DOMAIN/g" $TEMP_DIR/ingress.yaml

# Update API URL in web deployment
echo "Updating API URL in web deployment..."
sed -i.bak "s|\${API_URL}|$API_URL|g" $TEMP_DIR/web-deployment.yaml
sed -i.bak "s|\${TIMESTAMP}|$TIMESTAMP|g" $TEMP_DIR/web-deployment.yaml
sed -i.bak "s|\${TIMESTAMP}|$TIMESTAMP|g" $TEMP_DIR/api-deployment.yaml

# If using Cloudflare, update the ingress configuration
if [ "$USE_CLOUDFLARE" = "true" ]; then
  echo "Configuring for Cloudflare integration..."

  # Update Cloudflare annotations
  sed -i.bak "s/# nginx.ingress.kubernetes.io\/ssl-redirect/nginx.ingress.kubernetes.io\/ssl-redirect/" $TEMP_DIR/ingress.yaml
  sed -i.bak "s/# nginx.ingress.kubernetes.io\/force-ssl-redirect/nginx.ingress.kubernetes.io\/force-ssl-redirect/" $TEMP_DIR/ingress.yaml
  sed -i.bak "s/# nginx.ingress.kubernetes.io\/proxy-buffer-size/nginx.ingress.kubernetes.io\/proxy-buffer-size/" $TEMP_DIR/ingress.yaml
  sed -i.bak "s/# nginx.ingress.kubernetes.io\/proxy-body-size/nginx.ingress.kubernetes.io\/proxy-body-size/" $TEMP_DIR/ingress.yaml
  sed -i.bak "s/# kubernetes.io\/ingress.class/kubernetes.io\/ingress.class/" $TEMP_DIR/ingress.yaml
  sed -i.bak "s/# external-dns.alpha.kubernetes.io\/hostname: \"yourdomain.com\"/external-dns.alpha.kubernetes.io\/hostname: \"$DOMAIN,$API_DOMAIN\"/" $TEMP_DIR/ingress.yaml
  sed -i.bak "s/# external-dns.alpha.kubernetes.io\/cloudflare-proxied/external-dns.alpha.kubernetes.io\/cloudflare-proxied/" $TEMP_DIR/ingress.yaml

  # Uncomment TLS configuration
  sed -i.bak "s/# tls:/tls:/" $TEMP_DIR/ingress.yaml
  sed -i.bak "s/# - hosts:/- hosts:/" $TEMP_DIR/ingress.yaml
  sed -i.bak "s/#   - yourdomain.com/  - $DOMAIN\n  - $API_DOMAIN/" $TEMP_DIR/ingress.yaml
  sed -i.bak "s/#   secretName: tls-secret/  secretName: tls-secret/" $TEMP_DIR/ingress.yaml

  echo "Ingress configured for domains: $DOMAIN and $API_DOMAIN with Cloudflare integration"
fi

# Apply Kubernetes manifests using kustomize with the temporary directory
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

if [ "$USE_CLOUDFLARE" = "true" ]; then
  echo "You can access the application at:"
  echo "- Web: https://$DOMAIN"
  echo "- API: https://$API_DOMAIN"
  echo "Note: Make sure your Cloudflare DNS is configured correctly to point to your cluster's external IP"
else
  echo "You can access the application at:"
  echo "- Web: http://$DOMAIN"
  echo "- API: http://$API_DOMAIN"
  echo "Note: nip.io automatically resolves these domains to $IP_ADDRESS"
  echo "You can check the ingress status with: kubectl get ingress -n $NAMESPACE"
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