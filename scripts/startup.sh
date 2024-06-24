#!/bin/bash

set -euo pipefail

VERBOSE=false

log() {
    echo "$1"
}

log_verbose() {
    if $VERBOSE; then
        echo "$1"
    fi
}

log_error() {
    echo "❌ Error: $1" >&2
    echo "Please email us at hello@kardinal.dev for assistance." >&2
    exit 1
}

run_command() {
    if $VERBOSE; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

setup_docker() {
    log "🐳 Setting up Docker..."
    while ! run_command docker info; do
        sleep 1
    done
    log_verbose "Docker is running."
}

start_minikube() {
    log "🚀 Starting Minikube..."
    total_memory=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    total_memory_mb=$((total_memory / 1024))
    run_command minikube start --driver=docker --cpus=$(nproc) --memory $total_memory_mb --disk-size 32g || log_error "Failed to start Minikube"
    run_command minikube addons enable ingress
    run_command minikube addons enable metrics-server
    run_command kubectl config set-context minikube
    log_verbose "Minikube started successfully."
}

install_istio() {
    log "🌐 Installing Istio..."
    run_command curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.1 TARGET_ARCH=x86_64 sh - || log_error "Failed to download Istio"
    cd istio-1.22.1
    export PATH=$PWD/bin:$PATH
    echo 'export PATH=$PATH:'"$PWD/bin" >> ~/.bashrc
    run_command istioctl install --set profile=demo -y || log_error "Failed to install Istio"
    cd ..
    log_verbose "Istio installed successfully."
}

install_addons() {
    log "🧩 Installing Kiali and other addons..."
    run_command kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/prometheus.yaml || log_error "Failed to install Prometheus"
    run_command kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/grafana.yaml || log_error "Failed to install Grafana"
    run_command kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/jaeger.yaml || log_error "Failed to install Jaeger"
    run_command kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/kiali.yaml || log_error "Failed to install Kiali"
    run_command kubectl rollout status deployment/kiali -n istio-system || log_error "Kiali deployment failed"
    log_verbose "Addons installed successfully."
}

install_kardinal() {
    log "🐦 Installing Kardinal..."
    run_command git clone https://github.com/kurtosis-tech/kardinal-demo-script.git || log_error "Failed to clone Kardinal demo script"
    cd kardinal-demo-script
    run_command /usr/bin/python3 -m pip install click || log_error "Failed to install click"
    mv kardinal-cli kardinal
    chmod u+x kardinal
    echo 'export PATH=$PATH:'"$PWD" >> ~/.bashrc
    cd ..
    log_verbose "Kardinal installed successfully."
}

setup_voting_app() {
    log "🗳️ Setting up voting app..."
    run_command minikube image build -t voting-app-ui -f ./Dockerfile ./voting-app-demo/voting-app-ui/ || log_error "Failed to build voting-app-ui image"
    run_command minikube image build -t voting-app-ui-v2 -f ./Dockerfile-v2 ./voting-app-demo/voting-app-ui/ || log_error "Failed to build voting-app-ui-v2 image"
    run_command kubectl create namespace voting-app
    run_command kubectl label namespace voting-app istio-injection=enabled
    run_command kubectl apply -n voting-app -f ./voting-app-demo/manifests/prod-only-demo.yaml || log_error "Failed to apply voting app manifests"
    log_verbose "Voting app set up successfully."
}

main() {
    if [ "$1" = "--verbose" ]; then
        VERBOSE=true
        log "Verbose mode enabled."
    fi

    setup_docker
    start_minikube
    install_istio
    install_addons
    install_kardinal
    setup_voting_app

    log "✅ Startup completed! Minikube, Istio, and Kardinal are ready."
    log "🔄 Please run: source ~/.bashrc"
}

main "$@"