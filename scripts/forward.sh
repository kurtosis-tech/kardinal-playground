#!/bin/bash

set -euo pipefail

NGROK_CONFIG_FILE="$HOME/.ngrok2/ngrok.conf"

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

# Function to create or update ngrok config
update_ngrok_config() {
    local dev_host="$1"

    mkdir -p "$(dirname "$NGROK_CONFIG_FILE")"
    
    # Create the basic configuration
    cat > "$NGROK_CONFIG_FILE" << EOF
authtoken: $NGROK_AUTHTOKEN
version: 2
tunnels:
  prod:
    proto: http
    addr: 8080
    host_header: prod.app.localhost
EOF

    # Add dev tunnel if dev_host is provided
    if [ -n "$dev_host" ]; then
        cat >> "$NGROK_CONFIG_FILE" << EOF
  dev:
    proto: http
    addr: 8080
    host_header: $dev_host   
EOF
    fi
}

# Function to start ngrok
start_ngrok() {
    echo "🌐 Starting ngrok..."
    if [ -n "$1" ]; then
        ngrok start --config="$NGROK_CONFIG_FILE" prod dev &
    else
        ngrok start --config="$NGROK_CONFIG_FILE" prod &
    fi
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

    local dev_host="${1:-}"
    update_ngrok_config "$dev_host"
    start_ngrok "$dev_host"

    echo "🎉 Port forwarding and ngrok setup complete!"
    echo "ℹ️ Access your services through the ngrok URLs provided above."
    echo "⚠️ Remember to use the ngrok URLs for accessing your services."

    # Keep the script running
    wait
}

# Run the main function with all arguments passed to the script
main "$@"