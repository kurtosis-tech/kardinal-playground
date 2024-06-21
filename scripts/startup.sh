#!/bin/bash

# Get the total memory in bytes
total_memory=$(awk '/MemTotal/ {print $2}' /proc/meminfo)

# Convert bytes to megabytes
total_memory_mb=$((total_memory / 1024))

# Start minikube
minikube start --driver=docker --cpus=$(nproc) --memory $total_memory_mb --disk-size 32g

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server

# Set kubectl context
kubectl config set-context minikube

# Install Istio 1.22.1
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.1 TARGET_ARCH=x86_64 sh -
cd istio-1.22.1
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
cd ..

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

echo "Installing Kurtosis..."
curl -s https://raw.githubusercontent.com/kurtosis-tech/kardinal-demo-script/master/install.sh -o install.sh && source install.sh

echo "Startup completed. Minikube, Istio, and Kurtosis are ready."