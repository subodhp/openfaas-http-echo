#!/bin/bash

# Hacky script for quick deployment of OpenFaaS and http-echo function on the vanilla k8s Cluster.
# Only for Development Setup Purpose

# Install OpenFaaS CLI on Local Node
curl -sL https://cli.openfaas.com | sudo sh

# Install Arkade CLI for easier installation of OpenFaaS
curl -SLsf https://dl.get-arkade.dev/ | sudo sh

# Install openfaas on local k8s cluster using arkade
arkade install openfaas

# Rollout the Gateway Service & login to OpenFaaS CLI
kubectl rollout status -n openfaas deploy/gateway
PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode; echo)
echo -n $PASSWORD | faas-cli login --gateway http://127.0.0.1:31112 --username admin --password-stdin

# Deploy Grafana for Function Metrics
kubectl create deployment grafana --image=docker.io/grafana/grafana -n openfaas

# Expose Grafana Service
kubectl expose deployment grafana --type=NodePort --port=80 --target-port=3000 --protocol=TCP -n openfaas

# Deploy the OpenFaaS templates required for Go
faas template store pull golang-http
faas new --lang golang-http go-http-echo
docker login
faas-cli build -f go-http-echo.yml
faas-cli push -f go-http-echo.yml 
faas-cli deploy -f go-http-echo.yml
