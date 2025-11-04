# WireMock Runner on Kubernetes

This project demonstrates how to deploy WireMock Runner in a Kubernetes cluster, configured to serve mock APIs from WireMock Cloud.

## Overview

This setup deploys WireMock Runner with:
- **Admin API** on port 9999
- **PayPal Invoicing API** mock on port 8080
- **GitHub REST API** mock on port 8081

The mock APIs are synchronized from WireMock Cloud and can be managed through the WireMock Cloud interface.

## Prerequisites

- Kubernetes cluster (local or remote)
  - For local development, [KIND](https://kind.sigs.k8s.io/) is recommended
- `kubectl` CLI tool installed and configured
- WireMock Cloud account and API token
  - Sign up at [https://www.wiremock.io/cloud](https://www.wiremock.io/cloud)
  - Get your API token from the WireMock Cloud dashboard

### Optional: Set up a local KIND cluster

If you don't have a Kubernetes cluster, you can create a local one with KIND:

```bash
# Install KIND (macOS)
brew install kind

# Create a cluster
kind create cluster --name wiremock-demo

# Verify the cluster is running
kubectl cluster-info
```

## Installation

### 1. Set up WireMock Cloud API Token

First, create a Kubernetes secret with your WireMock Cloud API token (which you can find in the [WireMock Cloud console](https://app.wiremock.cloud/account/security)):

```bash
./set-secret.sh <your-wmc-api-token>
```

This creates a secret named `wiremock-cloud-token` that will be used by the WireMock Runner to authenticate with WireMock Cloud.

### 2. Configure Mock APIs

The `.wiremock/wiremock.yaml` file defines which mock APIs to serve:

```yaml
services:
  paypal-invoicing:
    type: REST
    name: "PayPal Invoicing API"
    port: 8080
    cloud_id: 24gzy
    originals:
      default: https://api-m.sandbox.paypal.com

  github-rest:
    type: REST
    name: "GitHub REST API"
    port: 8081
    cloud_id: r15v6
    originals:
      default: https://api.github.com
```

Update the `cloud_id` values to match your WireMock Cloud mock API IDs.

### 3. Deploy to Kubernetes

Run the installation script:

```bash
./install-wiremock.sh
```

This script will:
1. Create a ConfigMap from the `.wiremock` directory
2. Deploy the WireMock Runner service and deployment
3. Set up ingress rules for accessing the APIs

## Accessing the Services

### Local Access (Port Forwarding)

For local development, use port forwarding to access the services:

```bash
kubectl port-forward service/wiremock-runner 9999:9999 8080:8080 8081:8081
```

Then access:
- Admin API: http://localhost:9999
- PayPal Invoicing mock: http://localhost:8080
- GitHub REST mock: http://localhost:8081

### Ingress Access

The project includes two ingress configurations:

#### Path-based Ingress (default)

Access services via paths on `wiremock.local`:
- Admin API: http://wiremock.local/admin
- PayPal mock: http://wiremock.local/paypal
- GitHub mock: http://wiremock.local/github

#### Host-based Ingress (alternative)

Access services via subdomains:
- Admin API: http://admin.wiremock.local
- PayPal mock: http://paypal.wiremock.local
- GitHub mock: http://github.wiremock.local

**Note:** For local development, add these entries to your `/etc/hosts`:
```
127.0.0.1 wiremock.local admin.wiremock.local paypal.wiremock.local github.wiremock.local
```

## Monitoring

### Check deployment status

```bash
kubectl get pods -l app=wiremock-runner
```

### View logs

```bash
kubectl logs -l app=wiremock-runner -f
```

### Check service status

```bash
kubectl get service wiremock-runner
```

## Configuration

### Environment Variables

The deployment uses these environment variables:

- `WMC_DEFAULT_MODE=serve`: Run in serve mode (serving mocks from WireMock Cloud)
- `WMC_ADMIN_PORT=9999`: Admin API port
- `WMC_API_TOKEN`: WireMock Cloud API token (from secret)

### Customizing the Deployment

To add more mock APIs:

1. Add a new service entry in `.wiremock/wiremock.yaml`
2. Update `wiremock-runner.yaml` to expose the new port
3. Add corresponding ingress rules if needed
4. Re-run `./install-wiremock.sh`

## Troubleshooting

### Pod not starting

Check pod events:
```bash
kubectl describe pod -l app=wiremock-runner
```

### ConfigMap issues

Verify the ConfigMap was created:
```bash
kubectl get configmap wiremock-config
kubectl describe configmap wiremock-config
```

### Secret issues

Verify the secret exists:
```bash
kubectl get secret wiremock-cloud-token
```

If not, re-run the `set-secret.sh` script.

### Connection issues

Verify services are running:
```bash
kubectl get all -l app=wiremock-runner
```

Test admin API connectivity:
```bash
kubectl port-forward service/wiremock-runner 9999:9999 &
curl http://localhost:9999/__admin/mappings
```

## Cleanup

To remove the deployment:

```bash
kubectl delete -f wiremock-runner.yaml
kubectl delete configmap wiremock-config
kubectl delete secret wiremock-cloud-token
```

To delete the KIND cluster:

```bash
kind delete cluster --name wiremock-demo
```

## Additional Resources

- [WireMock Cloud Documentation](https://www.wiremock.io/docs)
- [WireMock Runner Documentation](https://wiremock.org/docs/solutions/wiremock-cloud/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)

## License

See [LICENSE.txt](LICENSE.txt) for details.
