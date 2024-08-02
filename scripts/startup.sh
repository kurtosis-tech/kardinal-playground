#!/bin/bash

set -euo pipefail

VERBOSE=false
TENANT_UUID=""
KARDINAL_CLI_PATH=""
KARDINAL_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/kardinal"
UUID_FILE="$KARDINAL_DATA_DIR/fk-tenant-uuid"


# Spinning cursor animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

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

run_command_with_spinner() {
    if $VERBOSE; then
        "$@"
    else
        "$@" >/dev/null 2>&1 &
        local pid=$!
        spinner $pid
        wait $pid
        return $?
    fi
}

setup_docker() {
    log "🐳 Setting up Docker..."
    while ! run_command_with_spinner docker info; do
        sleep 1
    done
    log_verbose "Docker is running."
    sleep 3
}

start_minikube() {
    log "🚀 Starting Minikube..."
    total_memory=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    total_memory_mb=$((total_memory / 1024))
    run_command_with_spinner minikube start --driver=docker --cpus=$(nproc) --memory $total_memory_mb --disk-size 32g || log_error "Failed to start Minikube"
    run_command_with_spinner minikube addons enable ingress
    run_command_with_spinner minikube addons enable metrics-server
    run_command_with_spinner kubectl config set-context minikube
    log_verbose "Minikube started successfully."
}

install_istio() {
    log "🌐 Installing Istio..."
    run_command_with_spinner sh -c 'curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.1 TARGET_ARCH=x86_64 sh -' || log_error "Failed to download Istio"
    cd istio-1.22.1
    export PATH=$PWD/bin:$PATH
    echo 'export PATH=$PATH:'"$PWD/bin" >> ~/.bashrc
    run_command_with_spinner istioctl install --set profile=demo -y || log_error "Failed to install Istio"
    cd ..
    log_verbose "Istio installed successfully."
}

setup_kardinal_cli() {
    log "🛠️ Setting up Kardinal CLI..."

    # Install Kardinal CLI using curl
    run_command_with_spinner sh -c 'curl get.kardinal.dev -sL | bash' || log_error "Failed to install Kardinal CLI"

    # Ensure the Kardinal data directory exists
    mkdir -p "$KARDINAL_DATA_DIR"

    # Find the kardinal CLI path
    KARDINAL_CLI_PATH=$(which kardinal)

    if [ -z "$KARDINAL_CLI_PATH" ]; then
        log_error "Failed to find kardinal CLI after installation"
        return 1
    fi

    log "✅ Kardinal CLI installed successfully. You can now use the 'kardinal' command directly."
    log_verbose "Kardinal CLI setup completed. The 'kardinal' command is now available at $KARDINAL_CLI_PATH."
}

deploy_kardinal_manager() {
    log "🚀 Deploying Kardinal Manager..."

    local kube_config="${HOME}/.kube/config"
    local minikube_dir="${HOME}/.minikube"

    # Check if the Kubernetes config file exists
    if [ ! -f "$kube_config" ]; then
        log_error "Kubernetes config file not found at $kube_config"
        return 1
    fi

    # Check if the Minikube directory exists
    if [ ! -d "$minikube_dir" ]; then
        log_error "Minikube directory not found at $minikube_dir"
        return 1
    fi

    log_verbose "About to run kardinal command to deploy manager..."

    # Run the kardinal command with spinner
    run_command_with_spinner kardinal manager deploy kloud-kontrol

    log_verbose "Kardinal command to deploy manager completed successfully"
    log "👩‍💼 Kardinal Manager Deployed"

    # Run the kardinal command for voting app deployment with spinner
    run_command_with_spinner kardinal deploy -k obd-demo.yaml

    log "🗳️ Initial version of voting app deployed"

    # Extract the Tenant UUID from the UUID file
    if [ ! -f "$UUID_FILE" ]; then
        log_error "UUID file not found at $UUID_FILE after deployment"
        return 1
    fi

    TENANT_UUID=$(cat "$UUID_FILE")
    log_verbose "Kardinal Manager deployed successfully with Tenant UUID: $TENANT_UUID"
}

silent_segment_track() {
  local username="${GITHUB_USER}"
  if [ -z "$username" ]; then
    echo "Error: GITHUB_USER environment variable is not set" >&2
    return 1
  fi

    curl -s -o /dev/null --location 'https://api.segment.io/v1/track' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "event": "start_codespace_demo",
        "userId": "'"$username"'",
        "writeKey": "UgpQTmrrzwTVdW4oDSPUlZRvjZ3CQJuj"
    }'
}

main() {
    # Check if an argument is provided
    if [ $# -gt 0 ] && [ "$1" = "--verbose" ]; then
        VERBOSE=true
        log "Verbose mode enabled."
    fi

    log "🕰️ This can take around 3 minutes! Familiarize yourself with the repository while this happens."

    silent_segment_track
    setup_docker
    start_minikube
    install_istio
    setup_kardinal_cli
    deploy_kardinal_manager

    log "✅ Startup completed! Minikube, Istio, Kontrol, and Kardinal Manager are ready."
    log "🏠 Tenant UUID: $TENANT_UUID"
    log "📊 Kardinal Dashboard: https://app.kardinal.dev/$(cat ~/.local/share/kardinal/fk-tenant-uuid)/traffic-configuration"
    exec bash
}

main "$@"
