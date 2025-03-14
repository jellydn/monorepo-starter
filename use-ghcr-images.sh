#!/bin/bash
set -e

# Default values
GHCR_USERNAME=${GHCR_USERNAME:-"jellydn"}
GHCR_REPO=${GHCR_REPO:-"monorepo-starter"}
GHCR_TAG=${GHCR_TAG:-"latest"}
GHCR_REGISTRY=${GHCR_REGISTRY:-"ghcr.io"}

# Display banner
echo "=========================================="
echo "  GitHub Container Registry Image Helper  "
echo "=========================================="
echo ""

# Check if .env file exists
if [ -f .env ]; then
  echo "Found .env file, loading variables..."
  export $(grep -v '^#' .env | xargs)
  echo "Using:"
  echo "- Username: $GHCR_USERNAME"
  echo "- Repository: $GHCR_REPO"
  echo "- Tag: $GHCR_TAG"
  echo "- Registry: $GHCR_REGISTRY"
else
  echo "No .env file found, using default values:"
  echo "- Username: $GHCR_USERNAME"
  echo "- Repository: $GHCR_REPO"
  echo "- Tag: $GHCR_TAG"
  echo "- Registry: $GHCR_REGISTRY"

  # Create .env file
  echo "Creating .env file with default values..."
  cat > .env << EOF
# GitHub Container Registry settings
# Replace with your GitHub username
GHCR_USERNAME=$GHCR_USERNAME
# Replace with your repository name
GHCR_REPO=$GHCR_REPO
# The registry URL (usually ghcr.io)
GHCR_REGISTRY=$GHCR_REGISTRY
# The tag to use (e.g., latest, main, v1.0.0)
GHCR_TAG=$GHCR_TAG
EOF
  echo ".env file created successfully!"
fi

echo ""
echo "Available options:"
echo "1. Pull and use GHCR images with docker-compose"
echo "2. Pull and use GHCR images with Kubernetes"
echo "3. Check available tags for images"
echo "4. Login to GitHub Container Registry"
echo "5. Exit"
echo ""

read -p "Select an option (1-5): " option

case $option in
  1)
    echo "Pulling and using GHCR images with docker-compose..."

    # Check if app_network exists
    if ! docker network inspect app_network >/dev/null 2>&1; then
      echo "Creating app_network..."
      docker network create app_network
    fi

    # Pull and run with docker-compose
    docker-compose up -d

    echo "Images pulled and containers started!"
    echo "You can access the applications at:"
    echo "- Web: http://localhost:3000"
    echo "- API: http://localhost:3001"
    ;;

  2)
    echo "Pulling and using GHCR images with Kubernetes..."

    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
      echo "Error: kubectl is not installed or not in PATH."
      echo "Please install kubectl first: https://kubernetes.io/docs/tasks/tools/"
      exit 1
    fi

    # Deploy to Kubernetes
    cd k8s
    USE_GHCR=true GHCR_USERNAME=$GHCR_USERNAME GHCR_REPO=$GHCR_REPO GHCR_TAG=$GHCR_TAG ./deploy.sh
    cd ..
    ;;

  3)
    echo "Checking available tags for images..."

    # Check if GitHub CLI is installed
    if command -v gh &> /dev/null; then
      echo "Using GitHub CLI to list tags..."

      # Check if logged in
      if ! gh auth status &> /dev/null; then
        echo "You need to login to GitHub first."
        gh auth login
      fi

      echo "Available tags for $GHCR_REPO-web:"
      gh api "/users/$GHCR_USERNAME/packages/container/$GHCR_REPO-web/versions" --jq '.[].metadata.container.tags[]' | sort

      echo "Available tags for $GHCR_REPO-api:"
      gh api "/users/$GHCR_USERNAME/packages/container/$GHCR_REPO-api/versions" --jq '.[].metadata.container.tags[]' | sort
    else
      echo "GitHub CLI not found. Please install it to check available tags:"
      echo "https://cli.github.com/manual/installation"
      echo ""
      echo "Alternatively, you can check the available tags at:"
      echo "https://github.com/$GHCR_USERNAME/$GHCR_REPO/pkgs/container/$GHCR_REPO-web"
      echo "https://github.com/$GHCR_USERNAME/$GHCR_REPO/pkgs/container/$GHCR_REPO-api"
    fi
    ;;

  4)
    echo "Logging in to GitHub Container Registry..."

    # Check if GITHUB_TOKEN is set
    if [ -z "$GITHUB_TOKEN" ]; then
      echo "GITHUB_TOKEN environment variable is not set."
      echo "You can create a personal access token at: https://github.com/settings/tokens"
      echo "The token needs 'read:packages' scope to pull images."
      echo ""
      read -p "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
    fi

    # Login to GHCR
    echo $GITHUB_TOKEN | docker login $GHCR_REGISTRY -u $GHCR_USERNAME --password-stdin

    echo "Successfully logged in to GitHub Container Registry!"
    ;;

  5)
    echo "Exiting..."
    exit 0
    ;;

  *)
    echo "Invalid option. Exiting..."
    exit 1
    ;;
esac