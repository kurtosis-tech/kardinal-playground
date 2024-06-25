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
    cat > kardinal << 'EOL'
#!/bin/bash

# Function to forward dev version
forward_dev() {
    echo "🛠️ Waiting for the dev version (voting-app-dev) to be ready..."

    # Wait for the deployment to be available
    kubectl wait --for=condition=available --timeout=60s deployment/voting-app-ui-dev -n voting-app || { echo "❌ Error: Timeout waiting for voting-app-dev deployment"; return 1; }

    # Wait for the pod to be created and running
    local timeout=120
    local start_time=$(date +%s)
    local pod_running=false

    while [ "$pod_running" = false ]; do
        if kubectl get pods -A | grep "voting-app-ui-dev" | grep "Running" > /dev/null; then
            pod_running=true
            echo "✅ voting-app-dev pod is running."
        else
            if [ $(($(date +%s) - start_time)) -ge ${timeout} ]; then
                echo "❌ Error: Timeout waiting for voting-app-dev pod to be running"
                echo "Debugging information:"
                echo "Deployment status:"
                kubectl describe deployment voting-app-ui-dev -n voting-app
                echo "Pods in all namespaces:"
                kubectl get pods -A
                echo "Events in the voting-app namespace:"
                kubectl get events -n voting-app --sort-by='.lastTimestamp'
                return 1
            fi

            echo "Waiting for voting-app-dev pod to be running... ($(( $timeout - $(date +%s) + $start_time )) seconds left)"
            sleep 5
        fi
    done

    # Get the full pod name
    local pod_name=$(kubectl get pods -A | grep "voting-app-ui-dev" | grep "Running" | awk '{print $2}')
    echo "Pod $pod_name is running. Checking readiness..."

    # Check if all containers in the pod are ready
    local containers_ready=$(kubectl get pod $pod_name -n voting-app -o jsonpath='{.status.containerStatuses[*].ready}' | grep -o "true" | wc -l)
    local total_containers=$(kubectl get pod $pod_name -n voting-app -o jsonpath='{.spec.containers[*].name}' | wc -w)

    if [ "$containers_ready" -ne "$total_containers" ]; then
        echo "❌ Error: Not all containers in pod $pod_name are ready"
        echo "Debugging information:"
        kubectl describe pod $pod_name -n voting-app
        return 1
    fi

    echo "🛠️ Port-forwarding the dev version (voting-app-dev)..."

    # Check if port 8081 is already in use
    if lsof -i :8081 > /dev/null 2>&1; then
        echo "⚠️ Port 8081 is already in use. Stopping the existing process..."
        kill $(lsof -t -i :8081) || true
        sleep 2
    fi

    sleep 7

    # Start port-forwarding
    kubectl port-forward -n voting-app deploy/voting-app-ui-dev 8081:80 > /dev/null 2>&1 &

    # Save the PID of the port-forward process
    local port_forward_pid=$!

    # Wait a moment to ensure the port-forward has started
    sleep 6

    # Check if the port-forward process is still running
    if kill -0 $port_forward_pid 2>/dev/null; then
        echo "✅ Port-forwarding started successfully (PID: $port_forward_pid)"
    else
        echo "❌ Failed to start port-forwarding"
        echo "Debugging information:"
        echo "Port 8081 status:"
        lsof -i :8081
        echo "Recent kubectl logs:"
        kubectl logs deployment/voting-app-ui-dev -n voting-app --tail=50
        return 1
    fi

    return 0
}

# Check if the command is create-dev-flow
if [ "$1" = "create-dev-flow" ]; then
    # Run the original kardinal command
    kardinal-original "$@"
    
    # If kardinal command was successful, run forward_dev
    if [ $? -eq 0 ]; then
        forward_dev
    fi
else
    # For all other commands, just pass through to kardinal-original
    kardinal-original "$@"
fi
EOL

    chmod u+x kardinal
    echo 'export PATH=$PATH:'"$PWD" >> ~/.bashrc
    cd ..
    log_verbose "Kardinal installed successfully with wrapper script."
}

setup_voting_app() {
    log "🗳️ Setting up voting app..."
    run_command_with_spinner minikube image build -t voting-app-ui -f ./Dockerfile ./voting-app-demo/voting-app-ui/ || log_error "Failed to build voting-app-prod image"
    run_command_with_spinner minikube image build -t voting-app-ui-dev -f ./Dockerfile-v2 ./voting-app-demo/voting-app-ui/ || log_error "Failed to build voting-app-dev image"
    run_command_with_spinner kubectl create namespace voting-app
    run_command_with_spinner kubectl label namespace voting-app istio-injection=enabled
    run_command_with_spinner kubectl apply -n voting-app -f ./voting-app-demo/manifests/prod-only-demo.yaml || log_error "Failed to apply voting app manifests"
    log_verbose "Voting app set up successfully."
}

forward_prod() {
    log "⏭️ Waiting for the prod version (voting-app-ui) to be ready..."

    local service_name="voting-app-ui"
    local namespace="voting-app"
    local timeout=120  # timeout in seconds

    local start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        local pod_status=$(kubectl get pods -n ${namespace} -l app=${service_name} -o jsonpath='{.items[0].status.phase}')
        
        # Check if the service has endpoints
        local endpoint_ip=$(kubectl get endpoints -n ${namespace} ${service_name} -o jsonpath='{.subsets[0].addresses[0].ip}')

        if [ "${pod_status}" = "Running" ] && [ -n "${endpoint_ip}" ]; then
            log_verbose "Service ${service_name} is ready and has a running pod with endpoints"
            break
        fi

        if [ $(($(date +%s) - start_time)) -ge ${timeout} ]; then
            log_error "Timeout waiting for service ${service_name} to be ready. Pod status: ${pod_status}, Endpoint IP: ${endpoint_ip}"
            return 1
        fi

        log_verbose "Waiting for service and pod to be ready..."
        sleep 5
    done

    log "⏭️ Port-forwarding the prod version (voting-app-ui)..."
    sleep 4
    nohup kubectl port-forward -n voting-app svc/voting-app-ui 8080:80 > /dev/null 2>&1 &

    return 0
}

start_kiali_dashboard() {
    log "📊 Starting Kiali dashboard..."
    nohup istioctl dashboard kiali &>/dev/null &
    log "✅ Kiali dashboard started."

    # Print the Kiali URL
    echo "⏩ Access Kiali at: https://$CODESPACE_NAME-20001.app.github.dev/kiali/console/graph/namespaces/?duration=60&refresh=10000&namespaces=voting-app&idleNodes=true&layout=kiali-dagre&namespaceLayout=kiali-dagre&animation=true"
}

silent_segment_track() {
  local username="${GITHUB_USER}"
  if [ -z "$username" ]; then
    echo "Error: GITHUB_USER environment variable is not set" >&2
    return 1
  fi

  curl -s -o /dev/null -X POST 'https://api.segment.io/v1/track' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Basic S3BBOGtEc3NKVTF6MGt1QlowcjJBODF3dUQxeWlzT246' \
    -d '{
      "userId": "'"$username"'",
      "event": "Added to kardinal-playground-users",
      "properties": {
        "table": "kardinal-playground-users",
        "username": "'"$username"'"
      }
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
    install_kardinal
    setup_voting_app
    forward_prod
    start_kiali_dashboard

    log "✅ Startup completed! Minikube, Istio, and Kardinal are ready."
    exec bash
}

main "$@"