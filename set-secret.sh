#!/bin/bash

# Script to create/update the WireMock Cloud API token secret in Kubernetes

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <wmc-api-token>"
  echo ""
  echo "Example: $0 your-api-token-here"
  exit 1
fi

WMC_API_TOKEN="$1"

echo "Creating/updating Kubernetes secret for WireMock Cloud API token..."

# Delete existing secret if it exists (ignore errors if it doesn't exist)
kubectl delete secret wiremock-cloud-token 2>/dev/null || true

# Create new secret
kubectl create secret generic wiremock-cloud-token \
  --from-literal=WMC_API_TOKEN="$WMC_API_TOKEN"

echo "✓ Secret 'wiremock-cloud-token' created successfully"
