#!/bin/bash

# Script to install WireMock Runner in a local KIND cluster

set -e

echo "Installing WireMock Runner in KIND cluster..."

# Get the absolute path to the .wiremock directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WIREMOCK_DIR="$SCRIPT_DIR/.wiremock"

# Verify the .wiremock directory exists
if [ ! -d "$WIREMOCK_DIR" ]; then
  echo "Error: .wiremock directory not found at $WIREMOCK_DIR"
  exit 1
fi

# Verify the secret exists
if ! kubectl get secret wiremock-cloud-token &>/dev/null; then
  echo "Error: Secret 'wiremock-cloud-token' not found."
  echo "Please run './set-secret.sh' first."
  exit 1
fi

# Apply the deployment and service (which includes PVC)
echo "Applying Kubernetes manifest..."
kubectl apply -f "$SCRIPT_DIR/wiremock-runner.yaml"

# Wait for PVC to be bound
echo "Waiting for PersistentVolumeClaim to be bound..."
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/wiremock-data --timeout=60s

# Create a temporary pod to copy files to the persistent volume
echo "Copying .wiremock files to persistent volume..."
kubectl delete pod wiremock-init 2>/dev/null || true

kubectl run wiremock-init --image=busybox:latest --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [
      {
        "name": "wiremock-init",
        "image": "busybox:latest",
        "command": ["sleep", "300"],
        "volumeMounts": [
          {
            "name": "wiremock-data",
            "mountPath": "/work"
          }
        ]
      }
    ],
    "volumes": [
      {
        "name": "wiremock-data",
        "persistentVolumeClaim": {
          "claimName": "wiremock-data"
        }
      }
    ]
  }
}'

# Wait for the init pod to be ready
kubectl wait --for=condition=ready pod/wiremock-init --timeout=60s

# Copy the .wiremock directory to the persistent volume
kubectl exec wiremock-init -- sh -c "rm -rf /work/.wiremock"
kubectl cp "$WIREMOCK_DIR" wiremock-init:/work/.wiremock

# Fix permissions on all copied files and directories
kubectl exec wiremock-init -- sh -c "chown -R 1001:1000 /work/.wiremock && chmod -R u+rwX,go+rX /work/.wiremock"

# Clean up the init pod
kubectl delete pod wiremock-init

# Restart the deployment to pick up the new files
echo "Restarting WireMock Runner deployment..."
kubectl rollout restart deployment/wiremock-runner
kubectl rollout status deployment/wiremock-runner --timeout=60s

echo ""
echo "✓ WireMock Runner deployed successfully!"
echo ""
echo "Exposed ports:"
echo "  - Admin API: 9999"
echo "  - PayPal Invoicing: 8080"
echo "  - GitHub REST: 8081"
echo ""
echo "To check deployment status:"
echo "  kubectl get pods -l app=wiremock-runner"
echo ""
echo "To view logs:"
echo "  kubectl logs -l app=wiremock-runner -f"
echo ""
echo "To access services (if using KIND):"
echo "  kubectl port-forward service/wiremock-runner 9999:9999 8080:8080 8081:8081"
