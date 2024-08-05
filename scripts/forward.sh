#!/bin/bash

set -euo pipefail

NGINX_CONF_DIR="/tmp/nginx"
NGINX_CONF_FILE="$NGINX_CONF_DIR/nginx.conf"
NGINX_LOG_DIR="/tmp/nginx/logs"
NGINX_PID_FILE="/tmp/nginx/nginx.pid"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to retry a command
retry() {
    local retries=$1
    shift
    local count=0
    until "$@"; do
        exit=$?
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            log "Command failed. Attempt $count/$retries:"
            sleep 5
        else
            log "Command failed after $retries attempts."
            return $exit
        fi
    done
    return 0
}

# Function to install nginx
install_nginx() {
    if ! command -v nginx &> /dev/null; then
        log "🛠️ Installing nginx..."
        sudo apt-get update &> /dev/null && sudo apt-get install -y nginx &> /dev/null
    fi
}

# Function to create nginx configuration
create_nginx_conf() {
    local host="${1:-prod.app.localhost}"
    
    mkdir -p "$NGINX_CONF_DIR"
    mkdir -p "$NGINX_LOG_DIR"
    
    cat > "$NGINX_CONF_FILE" << EOF
worker_processes 1;
error_log $NGINX_LOG_DIR/error.log debug;
pid $NGINX_PID_FILE;

events {
    worker_connections 1024;
}

http {
    access_log $NGINX_LOG_DIR/access.log;

    map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ''      close;
    }

    upstream istio_ingress {
        server 127.0.0.1:9080;
    }

    server {
        listen 8080;
        server_name _;

        location / {
            proxy_pass http://istio_ingress;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Forwarded-Port \$server_port;
            proxy_set_header X-Forwarded-Host \$host;

            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection \$connection_upgrade;
        }
    }
}
EOF
}

# Function to stop nginx
stop_nginx() {
    log "🛑 Stopping nginx..."
    if [ -f "$NGINX_PID_FILE" ]; then
        sudo nginx -s stop -c "$NGINX_CONF_FILE" &> /dev/null
        sleep 2
        if [ -f "$NGINX_PID_FILE" ]; then
            log "⚠️ nginx didn't stop gracefully. Forcing stop..."
            sudo kill -9 $(cat "$NGINX_PID_FILE") &> /dev/null || true
            sudo rm -f "$NGINX_PID_FILE"
        fi
    else
        log "No nginx PID file found. Attempting to kill any running nginx processes..."
        sudo pkill -9 nginx &> /dev/null || true
    fi
    log "✅ nginx stopped."
}

# Function to start nginx
start_nginx() {
    log "🚀 Starting nginx..."
    sudo nginx -c "$NGINX_CONF_FILE" &> /dev/null
}

# Function to check if port is listening
check_port() {
    log "Checking if port 8080 is listening..."
    sleep 2  # Give nginx a moment to start up
    if sudo lsof -i :8080 | grep LISTEN &> /dev/null; then
        log "✅ Port 8080 is listening"
        return 0
    else
        log "❌ Port 8080 is not listening"
        return 1
    fi
}

# Function to forward the Istio ingress gateway
forward_gateway() {
    log "🛠️ Checking if Istio ingress gateway is already forwarded..."
    if ! pgrep -f "kubectl port-forward -n istio-system service/istio-ingressgateway 9080:80" > /dev/null; then
        log "🛠️ Forwarding Istio ingress gateway to port 9080..."
        kubectl port-forward -n istio-system service/istio-ingressgateway 9080:80 &> /dev/null &
    else
        log "✅ Istio ingress gateway is already forwarded."
    fi
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log "❌ kubectl could not be found. Please ensure it's installed and in your PATH."
        exit 1
    fi
}

# Function to check if gh CLI is available
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log "❌ GitHub CLI (gh) could not be found. Please ensure it's installed and in your PATH."
        exit 1
    fi
}

# Main function
main() {
    check_kubectl
    check_gh_cli

    log "🔪 Killing any existing processes..."
    stop_nginx
    pkill -f "kubectl port-forward" &> /dev/null || true
    pkill -f "gh codespace ports forward" &> /dev/null || true

    local host="${1:-prod.app.localhost}"
    
    install_nginx
    create_nginx_conf "$host"
    retry 3 start_nginx
    retry 3 check_port
    retry 3 forward_gateway

    log "🎉 Setup complete!"
    log "🔀 Host header is set to: $host"

    log "ℹ️ Access your services through the Codespaces URL:"
    log "   https://$CODESPACE_NAME-8080.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"

    # Keep the script running
    wait
}

# Run the main function with all arguments passed to the script
main "$@"