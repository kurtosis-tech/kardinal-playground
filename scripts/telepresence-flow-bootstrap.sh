#!/bin/bash

BOUTIQUE_DEMO_APP_REPO="https://github.com/kurtosis-tech/new-obd.git"
BOUTIQUE_DEMO_APP_DIRNAME="new-obd"

set -euo pipefail

# Source the common script
source ./scripts/common.sh

download_boutique_repo() {
  log "⏬ Downloading the frontend project from the boutique demo app repository..."
  if [ -d "$BOUTIQUE_DEMO_APP_DIRNAME" ]; then
    log "The folder '$BOUTIQUE_DEMO_APP_DIRNAME' already exists, so it means the project has bean already downloaded"
  else
    run_command_with_spinner git clone --no-checkout $BOUTIQUE_DEMO_APP_REPO || log_error "Failed to download the frontend project"
    cd $BOUTIQUE_DEMO_APP_DIRNAME
    git sparse-checkout init --cone
    git sparse-checkout set src/frontend
    git checkout main
    log_verbose "Frontend project successfully downloaded."
  fi
}

telepresence_install() {
  log "🗂️ Checking if Telepresence is already installed..."
  if check_binary_file_exists "/usr/local/bin/telepresence"; then
    log_verbose "Telepresence CLI is already installed, skipping installation."
  else
    log "⏬ Installing Telepresence CLI..."
    run_command_with_spinner sudo curl -fL https://app.getambassador.io/download/tel2oss/releases/download/v2.19.1/telepresence-linux-amd64 -o /usr/local/bin/telepresence || log_error "Failed to download the Telepresence CLI tool"
    sudo chmod a+x /usr/local/bin/telepresence
    log_verbose "Telepresence CLI successfully installed."
  fi

  log "🗂️ Checking if Telepresence manager is already installed in the cluster..."
  if check_k8s_service_exists_in_namespace "traffic-manager" "ambassador"; then
    log_verbose "Telepresence manager is already installed in the cluster, skipping installation."
  else
    log "🌐 Installing Telepresence traffic manager in the cluster..."
    run_command_with_spinner telepresence helm install --set trafficManager.serviceMesh.type=istio
    log_verbose "Telepresence traffic manager successfully installed."
  fi
}

telepresence_connect() {
  log "🔌 Connecting Telepresence to Kardinal prod namespace..."
  run_command_with_spinner sudo telepresence --kubeconfig=/home/codespace/.kube/config connect -n prod || log_error "Failed to connect Telepresence"
  log_verbose "Telepresence successfully connected."
}


main() {
    # Check if an argument is provided
    if [ $# -gt 0 ] && [ "$1" = "--verbose" ]; then
        VERBOSE=true
        log "Verbose mode enabled."
    fi

    # log "🕰️ This can take around 3 minutes! Familiarize yourself with the repository while this happens."

    download_boutique_repo
    telepresence_install
    telepresence_connect

    # log "✅ Startup completed! Minikube, Istio, Kontrol, and Kardinal Manager are ready."
    # log "🏠 Tenant UUID: $TENANT_UUID"
    # log "📊 Kardinal Dashboard: https://app.kardinal.dev/$(cat ~/.local/share/kardinal/fk-tenant-uuid)/traffic-configuration"
    # exec bash
}

main "$@"