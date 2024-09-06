#!/bin/bash

set -euo pipefail

# Source the common script
source ./scripts/common.sh

run_frontend() {
    export CARTSERVICEHOST="cartservice"
    export PRODUCTCATALOGSERVICEHOST="productcatalogservice"
    cd ./src/frontend
    go build -o frontend
    ./frontend
}

main() {
    # Check if an argument is provided
    if [ $# -gt 0 ] && [ "$1" = "--verbose" ]; then
        VERBOSE=true
        log "Verbose mode enabled."
    fi

    run_frontend

}

main "$@"
