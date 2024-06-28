#!/bin/bash

set -euo pipefail

VERBOSE=false

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

install_addons() {
    log "🧩 Installing Kiali and other addons..."
    run_command_with_spinner kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/prometheus.yaml || log_error "Failed to install Prometheus"
    run_command_with_spinner kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/grafana.yaml || log_error "Failed to install Grafana"
    run_command_with_spinner kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/jaeger.yaml || log_error "Failed to install Jaeger"
    run_command_with_spinner kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/kiali.yaml || log_error "Failed to install Kiali"
    run_command_with_spinner kubectl rollout status deployment/kiali -n istio-system || log_error "Kiali deployment failed"
    log_verbose "Addons installed successfully."
}

run_kontrol_container() {
    log "🎮 Running Kontrol container..."
    run_command_with_spinner docker run -d -p 8080:8080 lostbean/kontrol-service || log_error "Failed to run Kontrol container"
    log_verbose "Kontrol container is running on port 8080."
}

deploy_kardinal_manager() {
    log "🚀 Deploying Kardinal Manager..."
    run_command_with_spinner kubectl apply -f manifests/kardinal-manager/k8s.yml || log_error "Failed to deploy Kardinal Manager"
    log_verbose "Kardinal Manager deployed successfully."
}

build_images() {
    log "🏗️ Building images..."
    run_command_with_spinner minikube image build -t voting-app-ui -f ./Dockerfile ./voting-app-demo/voting-app-ui/ || log_error "Failed to build voting-app-prod image"
    run_command_with_spinner minikube image build -t voting-app-ui-dev -f ./Dockerfile-v2 ./voting-app-demo/voting-app-ui/ || log_error "Failed to build voting-app-dev image"
    log_verbose "Demo images built successfully."
}

start_kiali_dashboard() {
    log "📊 Starting Kiali dashboard..."
    nohup istioctl dashboard kiali &>/dev/null &
    log "✅ Kiali dashboard started."

    # Print the Kiali URL
    echo "⏩ Access Kiali at: https://$CODESPACE_NAME-20001.app.github.dev/kiali/console/graph/namespaces/?duration=60&refresh=10000&namespaces=voting-app&idleNodes=true&layout=kiali-dagre&namespaceLayout=kiali-dagre&animation=true"
}

setup_kardinal_cli() {
    log "🛠️ Setting up Kardinal CLI..."
    
    # Pull the Kardinal CLI image
    run_command_with_spinner docker pull kurtosistech/kardinal-cli || log_error "Failed to pull Kardinal CLI image"
    
    # Create a wrapper script for the kardinal command
    cat > /usr/local/bin/kardinal << EOL
#!/bin/bash
docker run --rm -it -v \${PWD}:/workdir -w /workdir kurtosistech/kardinal-cli "\$@"
EOL
    
    # Make the wrapper script executable
    chmod +x /usr/local/bin/kardinal
    
    log_verbose "Kardinal CLI setup completed. You can now use the 'kardinal' command."
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
    install_addons
    run_kontrol_container
    deploy_kardinal_manager
    build_images
    setup_kardinal_cli
    start_kiali_dashboard

    log "✅ Startup completed! Minikube, Istio, Kontrol, and Kardinal Manager are ready."
    exec bash
}

main "$@"