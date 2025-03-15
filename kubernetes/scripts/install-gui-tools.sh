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

# Set the current context to the cluster
kubectl config use-context "kind-${CLUSTER_NAME}"

# Function to display the menu
display_menu() {
    clear
    echo "====================================================="
    echo "Kubernetes GUI Tools Installer"
    echo "====================================================="
    echo ""
    echo "Choose a GUI tool to install/launch:"
    echo ""
    echo "1) Kubernetes Dashboard (Web-based UI)"
    echo "2) K9s (Terminal-based UI)"
    echo "3) Lens Desktop (Standalone Application)"
    echo "4) Install all tools"
    echo "5) Exit"
    echo ""
    echo "====================================================="
    echo ""
}

# Function to install Kubernetes Dashboard
install_dashboard() {
    echo "Installing Kubernetes Dashboard..."
    ./k8s/install-dashboard.sh
}

# Function to install K9s
install_k9s() {
    echo "Installing K9s..."
    ./k8s/install-k9s.sh
}

# Function to install Lens Desktop
install_lens() {
    echo "Installing Lens Desktop..."
    ./k8s/install-lens.sh
}

# Main loop
while true; do
    display_menu
    read -p "Enter your choice [1-5]: " choice

    case $choice in
        1)
            install_dashboard
            read -p "Press Enter to continue..."
            ;;
        2)
            install_k9s
            read -p "Press Enter to continue..."
            ;;
        3)
            install_lens
            read -p "Press Enter to continue..."
            ;;
        4)
            echo "Installing all Kubernetes GUI tools..."
            install_dashboard
            install_k9s
            install_lens
            read -p "Press Enter to continue..."
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            read -p "Press Enter to continue..."
            ;;
    esac
done