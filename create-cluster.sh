#!/bin/bash

kind create cluster --config kind.config.yaml --name wiremock-demo

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.4/deploy/static/provider/kind/deploy.yaml
echo "Waiting for ingress-nginx to come up... ⏳"
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s