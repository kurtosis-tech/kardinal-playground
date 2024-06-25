#!/bin/bash

set -euo pipefail

log_error() {
    echo "❌ Error: $1" >&2
    echo "Please check your Kubernetes setup and try again." >&2
    exit 1
}

forward_prod() {
    echo "⏩ Port-forwarding the prod version (voting-app-main)..."
    kubectl port-forward -n voting-app svc/voting-app-ui 8080:80 &
    echo "✅ Prod version available at: http://localhost:8080"
}

forward_dev() {
    echo "🛠️ Port-forwarding the dev version (voting-app-dev)..."
    kubectl port-forward -n voting-app deploy/voting-app-ui-v2 8081:80 &
    echo "✅ Dev version available at: http://localhost:8081"
}

main() {
    if [ "$#" -eq 0 ]; then
        forward_prod
    elif [ "$1" == "dev" ]; then
        forward_dev
    else
        echo "ℹ️ Usage: $0 [dev]"
        echo "   Run without arguments to forward main version"
        echo "   Run with 'dev' argument to forward dev version"
        exit 1
    fi

    echo "🎉 Port-forwarding initiated successfully!"
}

main "$@"