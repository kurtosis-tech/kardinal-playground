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

install_kardinal() {
    log "🐦 Installing Kardinal..."
    run_command_with_spinner git clone https://github.com/kurtosis-tech/kardinal-demo-script.git || log_error "Failed to clone Kardinal demo script"
    cd kardinal-demo-script
    run_command_with_spinner /usr/bin/python3 -m pip install click || log_error "Failed to install click"
    mv kardinal-cli kardinal-original
    chmod u+x kardinal-original

    log_verbose "Creating Kardinal wrapper script..."
    cat > kardinal << EOL
#!/bin/bash

# Function to forward dev version
forward_dev() {
    sleep 3 # we sleep for a bit as the service can take a few seconds to come alive
    echo "🛠️ Port-forwarding the dev version (voting-app-dev)..."
    nohup kubectl port-forward -n voting-app deploy/voting-app-ui-v2 8081:80 > /dev/null 2>&1 &
    echo "✅ Dev version available at: http://localhost:8081"
}

# Check if the command is create-dev-flow
if [ "\$1" = "create-dev-flow" ]; then
    # Run the original kardinal command
    kardinal-original "\$@"
    
    # If kardinal command was successful, run forward_dev
    if [ \$? -eq 0 ]; then
        forward_dev
    fi
else
    # For all other commands, just pass through to kardinal-original
    kardinal-original "\$@"
fi
EOL

    chmod u+x kardinal
    echo 'export PATH=$PATH:'"$PWD" >> ~/.bashrc
    cd ..
    log_verbose "Kardinal installed successfully with wrapper script."
}

setup_voting_app() {
    log "🗳️ Setting up voting app..."
    run_command_with_spinner minikube image build -t voting-app-ui -f ./Dockerfile ./voting-app-demo/voting-app-ui/ || log_error "Failed to build voting-app-ui image"
    run_command_with_spinner minikube image build -t voting-app-ui-v2 -f ./Dockerfile-v2 ./voting-app-demo/voting-app-ui/ || log_error "Failed to build voting-app-ui-v2 image"
    run_command_with_spinner kubectl create namespace voting-app
    run_command_with_spinner kubectl label namespace voting-app istio-injection=enabled
    run_command_with_spinner kubectl apply -n voting-app -f ./voting-app-demo/manifests/prod-only-demo.yaml || log_error "Failed to apply voting app manifests"
    log_verbose "Voting app set up successfully."
}

forward_prod() {
    sleep 3 # we sleep for a bit as the service can take a few seconds to come alive
    log "⏭️ Port-forwarding the prod version (voting-app-ui)..."
    nohup kubectl port-forward -n voting-app svc/voting-app-ui 8080:80 > /dev/null 2>&1 &
    log "✅ Prod version available at: http://localhost:8080"
}

main() {
    # Check if an argument is provided
    if [ $# -gt 0 ] && [ "$1" = "--verbose" ]; then
        VERBOSE=true
        log "Verbose mode enabled."
    fi

    log "🕰️ This can take around 3 minutes! Familiarize yourself with the repository while this happens."

    setup_docker
    start_minikube
    install_istio
    install_addons
    install_kardinal
    setup_voting_app
    forward_prod

    log "✅ Startup completed! Minikube, Istio, and Kardinal are ready."
    echo "🚨 IMPORTANT: You may need to run 'source ~/.bashrc' to update your PATH. Otherwise, commands might not be found."
    exec bash
}

main "$@"