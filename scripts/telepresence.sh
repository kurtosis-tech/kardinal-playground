#!/bin/bash
set -euo pipefail

# Source the common script
source ./scripts/common.sh

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
  log "🚀 Starting the Telepresence daemon..."
  sudo telepresence daemon-foreground ~/.cache/telepresence/logs/ ~/.config/telepresence/ &
  log "Telepresence daemon successfully started."
}

main() {
    # Check if an argument is provided
    if [ $# -gt 0 ] && [ "$1" = "--verbose" ]; then
        VERBOSE=true
        log "Verbose mode enabled."
    fi

    telepresence_install

    log "✅ Telepresence installation completed!"
}

main "$@"
