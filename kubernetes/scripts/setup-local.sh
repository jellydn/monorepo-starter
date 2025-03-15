#!/bin/bash
set -e

# Configuration
CLUSTER_NAME=${CLUSTER_NAME:-"monorepo-cluster"}
REGISTRY_NAME=${REGISTRY_NAME:-"kind-registry"}
REGISTRY_PORT=${REGISTRY_PORT:-5000}
IP_ADDRESS=${IP_ADDRESS:-"127.0.0.1"}

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "kind is not installed. Please install it first: https://kind.sigs.k8s.io/docs/user/quick-start/"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install it first: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Create a local registry
if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" 2>/dev/null || true)" != 'true' ]; then
  echo "Creating local registry..."
  docker run -d --restart=always -p "${REGISTRY_PORT}:5000" --name "${REGISTRY_NAME}" registry:2
fi

# Create kind cluster configuration
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REGISTRY_PORT}"]
    endpoint = ["http://${REGISTRY_NAME}:5000"]
EOF

# Create kind cluster
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Creating kind cluster: ${CLUSTER_NAME}..."
  kind create cluster --name "${CLUSTER_NAME}" --config kind-config.yaml
else
  echo "Cluster ${CLUSTER_NAME} already exists."
fi

# Connect the registry to the cluster network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}" 2>/dev/null)" = 'null' ]; then
  echo "Connecting registry to kind network..."
  docker network connect "kind" "${REGISTRY_NAME}"
fi

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
echo "Waiting for NGINX Ingress Controller to be ready..."
echo "This may take a minute or two..."

# Give the controller some time to create the resources
sleep 30

# Wait for the ingress controller pod to be ready
echo "Checking if ingress controller pods are running..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s || {
    echo "Ingress controller pods are not ready yet. Checking pod status..."
    kubectl get pods -n ingress-nginx
    echo "You may need to wait a bit longer for the ingress controller to be fully ready."
    echo "Continue with the setup anyway..."
  }

# Set the current context to the new cluster
kubectl config use-context "kind-${CLUSTER_NAME}"

echo "Local Kubernetes environment is ready!"
echo "Registry: localhost:${REGISTRY_PORT}"
echo "To deploy your application, run: REGISTRY_URL=localhost:${REGISTRY_PORT} ./kubernetes/scripts/deploy-local.sh"
echo "After deployment, you can access:"
echo "- Web: http://demo-app.${IP_ADDRESS}.nip.io"
echo "- API: http://api-demo-app.${IP_ADDRESS}.nip.io"
echo "Note: nip.io automatically resolves these domains to ${IP_ADDRESS}"

# Clean up
rm -f kind-config.yaml