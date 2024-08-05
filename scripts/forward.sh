#!/bin/bash

set -euo pipefail

# Function to forward the Istio ingress gateway
forward_gateway() {
    echo "🛠️ Checking if Istio ingress gateway is already forwarded..."
    if ! pgrep -f "kubectl port-forward -n istio-system service/istio-ingressgateway 8080:80" > /dev/null; then
        echo "🛠️ Forwarding Istio ingress gateway to port 8080..."
        kubectl port-forward -n istio-system service/istio-ingressgateway 8080:80 &
    else
        echo "✅ Istio ingress gateway is already forwarded."
    fi
}

# Function to start ngrok
start_ngrok() {
    local host_header=${1:-"prod.app.localhost"}
    echo "🌐 Starting ngrok with host header: $host_header"
    ngrok http 8080 --host-header="$host_header" &
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl could not be found. Please ensure it's installed and in your PATH."
        exit 1
    fi
}

# Main function
main() {
    check_kubectl

    echo "🔪 Killing any existing ngrok processes..."
    pkill -f ngrok || true

    forward_gateway

    if [ $# -eq 0 ]; then
        start_ngrok
    else
        start_ngrok "$1"
    fi

    echo "🎉 Port forwarding and ngrok setup complete!"
    echo "ℹ️ Access your services through the ngrok URL provided above."
    echo "⚠️ Remember to use the ngrok URL for accessing your services."

    # Keep the script running
    wait
}

# Run the main function with all arguments passed to the script
main "$@"