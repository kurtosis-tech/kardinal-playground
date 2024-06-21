#!/bin/bash

set -euo pipefail

# Wait for Docker to start
echo "Waiting for Docker to start..."
while ! docker info >/dev/null 2>&1; do
    sleep 1
done
echo "Docker is running."

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
echo 'export PATH=$PATH:'"$PWD/bin" >> ~/.bashrc
istioctl install --set profile=demo -y
cd ..

# Install Kiali and other addons
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/jaeger.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/kiali.yaml
kubectl rollout status deployment/kiali -n istio-system


echo "Installing Kardinal..."
git clone https://github.com/kurtosis-tech/kardinal-demo-script.git
cd kardinal-demo-script
/usr/bin/python3 -m pip install click
mv kardinal-cli kardinal
chmod u+x kardinal
echo 'export PATH=$PATH:'"$PWD" >> ~/.bashrc
cd ..

# Create voting-app namespace and enable Istio injection
minikube image build -t voting-app-ui -f ./Dockerfile ./voting-app-demo/voting-app-ui/
minikube image build -t voting-app-ui-v2 -f ./Dockerfile-v2 ./voting-app-demo/voting-app-ui/
kubectl create namespace voting-app
kubectl label namespace voting-app istio-injection=enabled
kubectl apply -n voting-app -f ./voting-app-demo/manifests/prod-only-demo.yaml

echo "Startup completed. Minikube, Istio, and Kardinal are ready."
echo "Run source ~/.bashrc"