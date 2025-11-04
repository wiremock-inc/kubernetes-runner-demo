#!/bin/bash

# Script to delete WireMock Runner from the Kubernetes cluster

set -e

echo "Deleting WireMock Runner from cluster..."

# Get the absolute path to the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Delete the deployment, service, and ingresses
echo "Deleting Kubernetes resources..."
kubectl delete -f "$SCRIPT_DIR/wiremock-runner.yaml" 2>/dev/null || echo "No resources found from manifest (may already be deleted)"

# Delete the ConfigMap
echo "Deleting ConfigMap..."
kubectl delete configmap wiremock-config 2>/dev/null || echo "ConfigMap not found (may already be deleted)"

# Optionally delete the secret (commented out by default to preserve credentials)
# Uncomment the following lines if you also want to delete the secret:
# echo "Deleting Secret..."
# kubectl delete secret wiremock-cloud-token 2>/dev/null || echo "Secret not found (may already be deleted)"

echo ""
echo "✓ WireMock Runner deleted successfully!"
echo ""
echo "To verify deletion:"
echo "  kubectl get pods -l app=wiremock-runner"
echo "  kubectl get services wiremock-runner"
echo "  kubectl get configmap wiremock-config"
echo ""
echo "Note: The secret 'wiremock-cloud-token' was NOT deleted."
echo "To delete it manually, run:"
echo "  kubectl delete secret wiremock-cloud-token"
echo ""
