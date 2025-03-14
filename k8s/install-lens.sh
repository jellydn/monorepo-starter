#!/bin/bash
set -e

# Configuration
CLUSTER_NAME=${CLUSTER_NAME:-"monorepo-cluster"}

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

echo "====================================================="
echo "Lens Desktop Installation Guide"
echo "====================================================="
echo ""
echo "Lens Desktop is a powerful Kubernetes IDE that provides a GUI for managing your Kubernetes clusters."
echo ""
echo "Installation steps:"
echo ""
echo "1. Download Lens Desktop from https://k8slens.dev/"
echo "   - For macOS: Download the .dmg file and drag to Applications"
echo "   - For Windows: Download and run the installer"
echo "   - For Linux: Download the AppImage or .deb/.rpm package"
echo ""
echo "2. Launch Lens Desktop"
echo ""
echo "3. Add your Kubernetes cluster to Lens:"
echo "   - Click 'Add Cluster' in the left sidebar"
echo "   - Select 'Add from kubeconfig'"
echo "   - Use the kubeconfig file at: $HOME/.kube/config"
echo "   - Select the context: kind-${CLUSTER_NAME}"
echo ""
echo "4. Explore your cluster through the Lens UI"
echo ""
echo "====================================================="
echo ""
echo "Would you like to open the Lens Desktop download page? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "https://k8slens.dev/"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open "https://k8slens.dev/"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        start "https://k8slens.dev/"
    else
        echo "Please visit https://k8slens.dev/ to download Lens Desktop"
    fi
fi

echo ""
echo "For more information, visit: https://docs.k8slens.dev/getting-started/"