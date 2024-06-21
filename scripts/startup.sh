#!/bin/bash

# Start minikube
minikube start --driver=docker --cpus=$(nproc) --memory 8192 --disk-size 32g

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server

# Set kubectl context
kubectl config set-context minikube

# Install Istio
istioctl install --set profile=demo -y

# Install Kiali and other addons
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/jaeger.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/kiali.yaml
kubectl rollout status deployment/kiali -n istio-system

# Start Minikube dashboard
minikube dashboard &

# Start Kiali dashboard
istioctl dashboard kiali &

# Add hostnames to /etc/hosts
echo "127.0.0.1 voting-app.localhost" | sudo tee -a /etc/hosts
echo "127.0.0.1 dev.voting-app.localhost" | sudo tee -a /etc/hosts

echo "Startup completed. Minikube and Istio are ready."

source kardinal_install.sh