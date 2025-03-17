#!/bin/bash

# Script to manually run database migrations in Kubernetes
# This is useful for development or when you need to run migrations outside of the normal deployment process

set -e

# Default values
NAMESPACE="monorepo-app"
CONTEXT=""
TIMESTAMP=$(date +%s)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace=*)
      NAMESPACE="${1#*=}"
      shift
      ;;
    --context=*)
      CONTEXT="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Set kubectl context if provided
if [ -n "$CONTEXT" ]; then
  KUBECTL="kubectl --context=$CONTEXT"
else
  KUBECTL="kubectl"
fi

echo "Running database migrations in namespace: $NAMESPACE"

# Create a temporary directory for kustomize
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy the migration job YAML to the temp directory
cat > $TEMP_DIR/migration-job.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration-manual-$TIMESTAMP
  namespace: $NAMESPACE
  labels:
    app: db-migration-manual
spec:
  backoffLimit: 3
  ttlSecondsAfterFinished: 3600
  template:
    metadata:
      labels:
        app: db-migration-manual
    spec:
      restartPolicy: OnFailure
      containers:
        - name: migration
          image: \$($KUBECTL get deployment -n $NAMESPACE api -o jsonpath='{.spec.template.spec.containers[0].image}')
          imagePullPolicy: Always
          command: ["npx", "prisma", "migrate", "deploy", "--schema=/app/packages/db/prisma/schema.prisma"]
          env:
            - name: DATABASE_URL
              value: "postgresql://postgres:postgres@postgres:5432/monorepo"
            - name: NODE_ENV
              value: "production"
      initContainers:
        - name: wait-for-db
          image: postgres:17-alpine
          command: ['sh', '-c',
            'until pg_isready -h postgres -p 5432 -U postgres; do echo waiting for database; sleep 2; done;']
EOF

# Apply the job
$KUBECTL apply -f $TEMP_DIR/migration-job.yaml

echo "Migration job created: db-migration-manual-$TIMESTAMP"
echo "To check the status, run:"
echo "$KUBECTL logs -n $NAMESPACE -l app=db-migration-manual -f"

# Wait for the job to complete
echo "Waiting for migration job to complete..."
$KUBECTL wait --for=condition=complete --timeout=300s job/db-migration-manual-$TIMESTAMP -n $NAMESPACE

echo "Migration completed successfully!"