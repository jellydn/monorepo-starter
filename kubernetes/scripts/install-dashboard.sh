#!/bin/bash
set -e

# Configuration
CLUSTER_NAME=${CLUSTER_NAME:-"monorepo-cluster"}
DASHBOARD_VERSION="v2.7.0"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install it first: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if the cluster exists
if ! kubectl config get-contexts | grep -q "kind-${CLUSTER_NAME}"; then
    echo "Cluster kind-${CLUSTER_NAME} not found. Please run setup-local.sh first."
    exit 1
fi

# Set the current context to the cluster
kubectl config use-context "kind-${CLUSTER_NAME}"

echo "Installing Kubernetes Dashboard ${DASHBOARD_VERSION}..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml

# Create a service account for dashboard access
echo "Creating dashboard service account and cluster role binding..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Wait for dashboard to be ready
echo "Waiting for Kubernetes Dashboard to be ready..."
kubectl wait --namespace kubernetes-dashboard \
  --for=condition=ready pod \
  --selector=k8s-app=kubernetes-dashboard \
  --timeout=180s || {
    echo "Dashboard pods are not ready yet. Checking pod status..."
    kubectl get pods -n kubernetes-dashboard
    echo "You may need to wait a bit longer for the dashboard to be fully ready."
  }

# Get the token for dashboard login
echo "Generating access token..."
if kubectl -n kubernetes-dashboard get secret admin-user-token &> /dev/null; then
  kubectl -n kubernetes-dashboard delete secret admin-user-token
fi

kubectl -n kubernetes-dashboard create token admin-user --duration=24h > dashboard-token.txt
echo "Access token saved to dashboard-token.txt"

echo "Starting Kubernetes Dashboard proxy..."
echo "To access the dashboard:"
echo "1. Run: kubectl proxy"
echo "2. Open: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo "3. Use the token from dashboard-token.txt to log in"
echo ""
echo "For security reasons, the token expires in 24 hours. To generate a new token, run:"
echo "kubectl -n kubernetes-dashboard create token admin-user --duration=24h"
echo ""
echo "To stop the proxy, press Ctrl+C"

# Start the proxy
kubectl proxy