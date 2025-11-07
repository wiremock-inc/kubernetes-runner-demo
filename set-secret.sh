#!/bin/bash

# Script to create/update the WireMock Cloud API token secret in Kubernetes

set -e

echo "Retrieving WireMock Cloud API token from local configuration..."

# Get the API token from the WireMock CLI config
WMC_API_TOKEN=$(wiremock config get api_token)

if [ -z "$WMC_API_TOKEN" ]; then
  echo "Error: No API token found in WireMock CLI configuration."
  echo ""
  echo "Please configure your API token first using:"
  echo "  wiremock login"
  echo ""
  echo "Or manually set it with:"
  echo "  wiremock config set api_token <your-token>"
  exit 1
fi

echo "Creating/updating Kubernetes secret for WireMock Cloud API token..."

# Delete existing secret if it exists (ignore errors if it doesn't exist)
kubectl delete secret wiremock-cloud-token 2>/dev/null || true

# Create new secret
kubectl create secret generic wiremock-cloud-token \
  --from-literal=WMC_API_TOKEN="$WMC_API_TOKEN"

echo "✓ Secret 'wiremock-cloud-token' created successfully"
