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

# Check if K9s is already installed
if command -v k9s &> /dev/null; then
    echo "K9s is already installed. Version: $(k9s version)"
    echo "To launch K9s, run: k9s"
    echo "Would you like to launch K9s now? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        k9s --context "kind-${CLUSTER_NAME}"
    fi
    exit 0
fi

echo "K9s is not installed. Installing K9s..."

# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
esac

# Install K9s based on the OS
case $OS in
    darwin)
        if command -v brew &> /dev/null; then
            echo "Installing K9s using Homebrew..."
            brew install k9s
        else
            echo "Homebrew not found. Please install Homebrew first: https://brew.sh/"
            echo "Or download K9s manually from: https://github.com/derailed/k9s/releases"
            exit 1
        fi
        ;;
    linux)
        echo "Installing K9s on Linux..."
        # Get the latest release version
        VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')

        # Download and install K9s
        curl -sL "https://github.com/derailed/k9s/releases/download/${VERSION}/k9s_${OS}_${ARCH}.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/k9s /usr/local/bin/
        echo "K9s installed successfully!"
        ;;
    *)
        echo "Unsupported OS: $OS"
        echo "Please download K9s manually from: https://github.com/derailed/k9s/releases"
        exit 1
        ;;
esac

echo "K9s installed successfully!"
echo "To launch K9s, run: k9s"
echo "Would you like to launch K9s now? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    k9s --context "kind-${CLUSTER_NAME}"
fi

echo ""
echo "For more information, visit: https://k9scli.io/topics/commands/"