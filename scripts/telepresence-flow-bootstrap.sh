#!/bin/bash

BOUTIQUE_DEMO_APP_REPO="https://github.com/kurtosis-tech/new-obd.git"

set -euo pipefail

# Source the common script
source ./scripts/common.sh

download_boutique_remo() {
  log "⏬ Downloading the frontend project from the boutique demo app repository..."
  run_command_with_spinner git clone --no-checkout $BOUTIQUE_DEMO_APP_REPO || log_error "Failed to download the frontend project"
  cd ./new-obd
  git sparse-checkout init --cone
  git sparse-checkout set src/frontend
  git checkout main
  log_verbose "Frontend project successfully downloaded."
}

install_telepresence() {
  log "⏬ Installing Telepresence CLI..."
  run_command_with_spinner curl -fL https://app.getambassador.io/download/tel2/linux/amd64/latest/telepresence -o /usr/local/bin/telepresence

  chmod a+x /usr/local/bin/telepresence
  log_verbose "Telepresence CLI successfully installed."

  log "⏬ Installing Telepresence traffic manager in the cluster..."
  run_command_with_spinner telepresence helm install --set trafficManager.serviceMesh.type=istio
  log_verbose "Telepresence traffic manager successfully installed."
}


main() {
    # Check if an argument is provided
    if [ $# -gt 0 ] && [ "$1" = "--verbose" ]; then
        VERBOSE=true
        log "Verbose mode enabled."
    fi

    # log "🕰️ This can take around 3 minutes! Familiarize yourself with the repository while this happens."

    download_boutique_remo

    # log "✅ Startup completed! Minikube, Istio, Kontrol, and Kardinal Manager are ready."
    # log "🏠 Tenant UUID: $TENANT_UUID"
    # log "📊 Kardinal Dashboard: https://app.kardinal.dev/$(cat ~/.local/share/kardinal/fk-tenant-uuid)/traffic-configuration"
    # exec bash
}

main "$@"