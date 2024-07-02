#!/bin/bash

set -euo pipefail

forward_dev() {
    echo "🛠️ Forwarding dev version (voting-app-dev)..."
    kubectl port-forward -n prod deploy/voting-app-ui-dev 8091:80 > /dev/null 2>&1 &
    echo "✅ Dev version forwarded to port 8091"
}

forward_prod() {
    echo "🚀 Forwarding prod version (voting-app-prod)..."
    kubectl port-forward -n prod svc/voting-app-ui 8090:80 > /dev/null 2>&1 &
    echo "✅ Prod version forwarded to port 8090"
}

forward_kiali() {
    echo "📊 Forwarding Kiali dashboard..."
    istioctl dashboard kiali --port=20001 > /dev/null 2>&1 &
    echo "✅ Kiali dashboard forwarded to port 20001"
}

kill_existing_forwards() {
    echo "🔪 Killing existing port-forwards..."
    pkill -f "kubectl port-forward.*voting-app" || true
    pkill -f "istioctl dashboard kiali" || true
}

forward_all() {
    kill_existing_forwards
    forward_prod
    forward_dev
    forward_kiali
}

print_usage() {
    echo "Usage: $0 [dev|prod|kiali|all]"
    echo "  dev  : Forward dev version (voting-app-dev) to port 8091"
    echo "  prod : Forward prod version (voting-app-prod) to port 8090"
    echo "  kiali: Forward Kiali dashboard to port 20001"
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
        kiali)
            kill_existing_forwards
            forward_kiali
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
    echo "📌 Remember to access Kiali at: https://$CODESPACE_NAME-20001.app.github.dev/kiali"
    echo "🔗 Prod app: https://$CODESPACE_NAME-8090.app.github.dev"
    echo "🔗 Dev app: https://$CODESPACE_NAME-8091.app.github.dev"
}

main "$@"