#!/bin/bash

set -euo pipefail

MAX_RETRIES=3
RETRY_DELAY=5

forward_dev() {
    echo "🛠️ Forwarding dev version (voting-app-dev)..."
    if retry_check_pod_status "voting-app-ui-dev" "prod"; then
        retry_port_forward -n prod deploy/voting-app-ui-dev 8091:80
        echo "✅ Dev version forwarded to port 8091"
    else
        echo "❌ Failed to forward dev version: pod is not running after retries"
    fi
}

forward_prod() {
    echo "🚀 Forwarding prod version (voting-app-prod)..."
    if retry_check_pod_status "voting-app-ui" "prod"; then
        retry_port_forward -n prod svc/voting-app-ui 8090:80
        echo "✅ Prod version forwarded to port 8090"
    else
        echo "❌ Failed to forward prod version: pod is not running after retries"
    fi
}

check_pod_status() {
    local pod_name=$1
    local namespace=$2
    local status
    status=$(kubectl get pods -n "$namespace" -l app="$pod_name" -o jsonpath='{.items[0].status.phase}')
    if [ "$status" = "Running" ]; then
        return 0
    else
        echo "Pod $pod_name in namespace $namespace is not running (status: $status)"
        return 1
    fi
}

retry_check_pod_status() {
    local pod_name=$1
    local namespace=$2
    local retries=0
    while [ $retries -lt $MAX_RETRIES ]; do
        if check_pod_status "$pod_name" "$namespace"; then
            return 0
        fi
        echo "Pod not ready. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
        ((retries++))
    done
    echo "Max retries reached. Pod is not in Running state."
    return 1
}

retry_port_forward() {
    local retries=0
    while [ $retries -lt $MAX_RETRIES ]; do
        if kubectl port-forward "$@" > /dev/null 2>&1 & then
            return 0
        fi
        echo "Port forward failed. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
        ((retries++))
    done
    echo "Max retries reached. Port forward failed."
    return 1
}

kill_existing_forwards() {
    echo "🔪 Killing existing port-forwards..."
    pkill -f "kubectl port-forward.*voting-app" || true
}

forward_all() {
    kill_existing_forwards
    forward_prod
    forward_dev
}

print_usage() {
    echo "Usage: $0 [dev|prod|all]"
    echo "  dev  : Forward dev version (voting-app-dev) to port 8091"
    echo "  prod : Forward prod version (voting-app-prod) to port 8090"
    echo "  all  : Forward all of the above (default if no argument is provided)"
}

main() {
    local command=${1:-all}
    
    case $command in
        dev)
            kill_existing_forwards
            forward_dev
            ;;
        prod)
            kill_existing_forwards
            forward_prod
            ;;
        all)
            forward_all
            ;;
        *)
            print_usage
            exit 1
            ;;
    esac

    echo "🎉 Port forwarding complete!"
    echo "🔗 Prod app: https://$CODESPACE_NAME-8090.app.github.dev"
    echo "🔗 Dev app: https://$CODESPACE_NAME-8091.app.github.dev"
}

main "$@"