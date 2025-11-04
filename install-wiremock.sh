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
  echo "Please run './set-secret.sh <your-token>' first."
  exit 1
fi

# Create ConfigMap from .wiremock directory
echo "Creating ConfigMap from .wiremock directory..."
kubectl delete configmap wiremock-config 2>/dev/null || true
kubectl create configmap wiremock-config --from-file="$WIREMOCK_DIR"

# Apply the deployment and service
echo "Applying Kubernetes manifest..."
kubectl apply -f "$SCRIPT_DIR/wiremock-runner.yaml"

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
