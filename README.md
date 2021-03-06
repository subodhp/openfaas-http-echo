# openfaas-http-echo

- [openfaas-http-echo](#openfaas-http-echo)
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
  - [Install OpenFaaS](#install-openfaas)
  - [OpenFaaS Installation on Kubernetes](#openfaas-installation-on-kubernetes)
  - [Access the OpenFaaS Infra](#access-the-openfaas-infra)
  - [Deploy Grafana for Function Metrics](#deploy-grafana-for-function-metrics)
- [Deploy Sample Functions to OpenFaaS](#deploy-sample-functions-to-openfaas)
- [Deploy the GoLang based HTTP Echo Function](#deploy-the-golang-based-http-echo-function)
- [References](#references)
- [Maintainer](#maintainer)

# Introduction

Sample OpenFaaS App on K8s which Reflects/Echo's the HTTP Data based on GoLang for Testing

# Prerequisites

* Working Kubernetes 1.11+ Cluster

## Install OpenFaaS

Install OpenFaaS CLI on the host

```bash
curl -sL https://cli.openfaas.com | sudo sh
```

I have used Arkade to install OpenFaaS on local Kubernetes Cluster, to install Arkade CLI

```bash
curl -SLsf https://dl.get-arkade.dev/ | sudo sh
```

## OpenFaaS Installation on Kubernetes

Make sure that the host on which you are going to run the following Arkade command has the correct AuthN/AuthZ setup with the Kubernetes Cluster.

```bash
arkade install openfaas
<output snipped>
```

To validate the components on K8s Cluster 

```bash
kubectl get pods -n openfaas
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
openfaas      alertmanager-57bd4559d7-59nxz              1/1     Running   0          3m33s
openfaas      basic-auth-plugin-7d4956689b-68wh6         1/1     Running   0          3m33s
openfaas      faas-idler-b85f98fb7-lcx7r                 1/1     Running   2          3m33s
openfaas      gateway-59b667b794-crncr                   2/2     Running   0          3m33s
openfaas      nats-5cd4dff7c8-8gkl9                      1/1     Running   0          3m33s
openfaas      prometheus-bcc84d4d5-btxrc                 1/1     Running   0          3m33s
openfaas      queue-worker-6cb888d49c-2qh6q              1/1     Running   3          3m33s
```

**Login to OpenFaaS CLI**

```bash
PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode; echo)
echo -n $PASSWORD | faas-cli login --username admin --password-stdin
```

## Access the OpenFaaS Infra

To deploy the gateway 

```bash
kubectl rollout status -n openfaas deploy/gateway
```

To portforward to access OpenFaaS UI

```bash
kubectl port-forward -n openfaas svc/gateway 8080:8080
```

The service can also be exposed over NodePort or LoadBalancer depending upon the infrastructure.

OpenFaaS UI can be accessed at http://127.0.0.1:8080/ui/ on localhost

![](screenshots/UI_Home.png)

Change the prometheus to be exported over NodePort/LoadBalancer service types to access it outside.

```bash
kubectl get svc -n openfaas
NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
alertmanager        ClusterIP   10.105.14.181    <none>        9093/TCP         19m
basic-auth-plugin   ClusterIP   10.108.176.255   <none>        8080/TCP         19m
gateway             ClusterIP   10.98.25.123     <none>        8080/TCP         19m
gateway-external    NodePort    10.104.83.141    <none>        8080:31112/TCP   19m
nats                ClusterIP   10.102.252.133   <none>        4222/TCP         19m
prometheus          NodePort    10.102.39.112    <none>        9090:32333/TCP   19m
```

## Deploy Grafana for Function Metrics

Deploy Grafana to connect to Prometheus to display the function metrics.

```bash
kubectl create deployment grafana --image=docker.io/grafana/grafana -n openfaas
```

Expose the Grafana service over NodePort/LoadBalancer depending upon your infrastructure, since I am using Single Node K8s cluster, I will use NodePort to expose Grafana.

```bash
kubectl expose deployment grafana --type=NodePort --port=80 --target-port=3000 --protocol=TCP -n openfaas
```

Validate the Grafana and Prometheus Pods and Services

```bash
kubectl get pods -n openfaas | grep -E 'grafana|prometheus'; kubectl get svc -n openfaas | grep -E 'grafana|prometheus'
grafana-7d6646ffc-xn9bs              1/1     Running   0          12m
prometheus-bcc84d4d5-btxrc           1/1     Running   0          9h
grafana             NodePort    10.102.28.74     <none>        80:31035/TCP     87s
prometheus          NodePort    10.102.39.112    <none>        9090:32333/TCP   9h
```

Note the NodePort ports for access, to keep them constant one can create yaml's definitions to apply.

Access the dashboard and set the password. Default user/pass is admin/admin.

Configure the Grafana to point to Prometheus Data Source in the namespace.

![](screenshots/Grafana_Data_Source.png)

Import the OpenFaaS Dashboard - https://grafana.com/grafana/dashboards/3526 & https://grafana.com/grafana/dashboards/3434 

Grafana Dashboard - 

![](screenshots/Grafana.png)

# Deploy Sample Functions to OpenFaaS

For CLI, set the URL

```bash
export OPENFAAS_URL=http://127.0.0.1:31112
```

Pickup the port from NodePort service type. Login to the CLI first.

Deploy the sample NodeInfo app from OpenFaaS Store

```bash
faas-cli store deploy NodeInfo
WARNING! Communication is not secure, please consider using HTTPS. Letsencrypt.org offers free SSL/TLS certificates.

Deployed. 202 Accepted.
URL: http://127.0.0.1:8080/function/nodeinfo
```

This app can be seen in the UI & App Response can be observed on the call.

![](screenshots/UI_NodeInfo_App.png)

![](screenshots/NodeInfo_Call.png)

# Deploy the GoLang based HTTP Echo Function

Inside the functions directory, initialize the function with pulling the template

```bash
faas template store pull golang-http
faas new --lang golang-http go-http-echo
```

Build the Docker Image Locally. Since I am running a single node cluster, the docker image built will be locally present, for multi-node cluster or proper deployments make sure to push the image to Registry or DockerHub with proper prerequisites of login creds. You can use "faas-cli push" to push to remote repo.

```bash
cd functions
faas-cli build -f go-http-echo.yml

docker images
REPOSITORY                           TAG                 IMAGE ID            CREATED             SIZE
subodhp/go-http-echo                         latest              0de669751925        2 minutes ago       25.1MB
<output snipped>
```
Login to Registry, in my case I am using public DockerHub Repo.

```bash
docker login
<perform successful login>

faas-cli push -f go-http-echo.yml 
[0] > Pushing go-http-echo [subodhp/go-http-echo:latest].
The push refers to repository [docker.io/subodhp/go-http-echo]
<output snipped>
```

Deploy the function.

```bash
faas-cli deploy -f go-http-echo.yml 
Deploying: go-http-echo.
WARNING! Communication is not secure, please consider using HTTPS. Letsencrypt.org offers free SSL/TLS certificates.

Deployed. 202 Accepted.
URL: http://127.0.0.1:8080/function/go-http-echo.openfaas-fn
```

Invoke the function via CLI.

```bash
echo -n "test" | faas-cli invoke go-http-echo
```

To remove the deployed function.

```bash
faas-cli remove -f go-http-echo.yml
```

Output of the function which includes headers from the requestor. It can be seen that for various clients, the fields are detected and responded by the function.

Using OpenFaaS CLI -

```bash
echo -n "test" | faas-cli invoke go-http-echo
Handling connection for 8080
Hello world, input was: test
Headers Received from Caller: 
Accept-Encoding: gzip
Content-Type: text/plain
X-Forwarded-For: 127.0.0.1:55340
X-Forwarded-Host: 127.0.0.1:8080
User-Agent: Go-http-client/1.1
```

**Access the OpenFaaS Gateway over NodePort for External Access**

```bash
echo -n "test" | faas-cli invoke --gateway http://127.0.0.1:31112 go-http-echo
```

The port 31112 may vary depending upon your gateway-external service port.

Using CURL -

```bash
curl -d test -X POST -H "test-header: subodh" http://127.0.0.1:8080/function/go-http-echo
Handling connection for 8080
Hello world, input was: test
Headers Received from Caller: 
User-Agent: curl/7.68.0
Accept: */*
Accept-Encoding: gzip
Content-Type: application/x-www-form-urlencoded
Test-Header: subodh
X-Forwarded-For: 127.0.0.1:59804
X-Forwarded-Host: 127.0.0.1:8080
```

Invocation via UI - 

![](screenshots/headers_gui.png)

Success!

# References
* https://docs.openfaas.com/deployment/kubernetes/
* https://hub.docker.com/repository/docker/subodhp/go-http-echo
* https://blog.alexellis.io/serverless-golang-with-openfaas/
* https://github.com/openfaas-incubator/golang-http-template

# Maintainer

Subodh at subodhpachghare@gmail.com
