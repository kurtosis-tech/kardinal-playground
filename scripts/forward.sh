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

# Function to validate and format the hostname
validate_and_format_hostname() {
    local input_host="$1"
    
    # Remove http:// or https:// if present
    input_host="${input_host#http://}"
    input_host="${input_host#https://}"
    
    # Check if the hostname is empty (use default) or matches the required patterns
    if [[ -z "$input_host" || "$input_host" == "prod.app.localhost" ]]; then
        echo "prod.app.localhost"
    elif [[ $input_host =~ ^dev-[a-zA-Z0-9]+\.app\.localhost$ ]]; then
        echo "$input_host"
    elif [[ $input_host =~ ^dev-[a-zA-Z0-9]+$ ]]; then
        echo "${input_host}.app.localhost"
    else
        log "❌ Invalid hostname format. It should be 'prod.app.localhost' or 'dev-[alphanumeric].app.localhost'"
        return 1
    fi
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

create_nginx_conf() {
    local host="$1"
    
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

        # Cache-busting headers
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
        if_modified_since off;
        expires off;
        etag off;

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

            # Additional cache-busting headers for proxied content
            proxy_set_header Pragma "no-cache";
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

check_prod_pods_health() {
    log "Checking for pods in the prod namespace..."
    local max_attempts=30
    local attempt=1
    local resources_exist=false
    local all_healthy=false

    # Wait for at least one resource to exist
    while [ $attempt -le $max_attempts ]; do
        if kubectl get pods -n prod --no-headers 2>/dev/null | wc -l | grep -q "0"; then
            log "Attempt $attempt/$max_attempts: No pods found in prod namespace. Waiting..."
            sleep 10
            ((attempt++))
        else
            resources_exist=true
            log "Pods found in prod namespace. Proceeding to health check."
            break
        fi
    done

    if ! $resources_exist; then
        log "❌ No pods appeared in the prod namespace after $max_attempts attempts"
        return 1
    fi

    # Reset attempt counter for health check
    attempt=1

    # Check health of existing pods
    while [ $attempt -le $max_attempts ]; do
        if kubectl get pods -n prod --no-headers | awk '{print $2}' | grep -qv '2/2'; then
            log "Attempt $attempt/$max_attempts: Some pods are not yet ready. Waiting..."
            sleep 10
            ((attempt++))
        else
            all_healthy=true
            break
        fi
    done

    if $all_healthy; then
        log "✅ All pods in the prod namespace are healthy and have status 2/2"
        return 0
    else
        log "❌ Not all pods in the prod namespace are healthy after $max_attempts attempts"
        return 1
    fi
}

# Main function
main() {
    log "🔪 Killing any existing processes..."
    stop_nginx
    pkill -f "kubectl port-forward" &> /dev/null || true
    pkill -f "gh codespace ports forward" &> /dev/null || true

    log "Waiting for all pods in the prod namespace to be healthy..."
    retry 3 check_prod_pods_health    

    local input_host="${1:-prod.app.localhost}"
    local validated_host
    
    if ! validated_host=$(validate_and_format_hostname "$input_host"); then
        log "Exiting due to invalid hostname."
        exit 1
    fi
    
    create_nginx_conf "$validated_host"
    retry 3 start_nginx
    retry 3 check_port
    retry 3 forward_gateway

    log "🎉 Setup complete!"
    log "🔀 Host header is set to: $validated_host"

    log "ℹ️ Access your services through the Codespaces URL:"
    log "   https://$CODESPACE_NAME-8080.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"

    # Keep the script running
    wait
}

# Run the main function with all arguments passed to the script
main "$@"