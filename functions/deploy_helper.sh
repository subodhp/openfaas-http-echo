#!/bin/bash

faas-cli remove -f go-http-echo.yml
sleep 10
faas-cli build -f go-http-echo.yml
sleep 4
faas-cli push -f go-http-echo.yml
sleep 4
faas-cli deploy -f go-http-echo.yml
sleep 4
kubectl get pods -n openfaas
sleep 1
kubectl get pods -n openfaas-fn
sleep 1
docker system prune -f
