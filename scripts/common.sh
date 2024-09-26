#!/bin/bash

set -euo pipefail

VERBOSE=false

# Spinning cursor animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

log() {
    echo "$1"
}

log_verbose() {
    if $VERBOSE; then
        echo "$1"
    fi
}

log_error() {
    echo "❌ Error: $1" >&2
    echo "Please email us at hello@kardinal.dev for assistance." >&2
    exit 1
}

run_command_with_spinner() {
    if $VERBOSE; then
        "$@"
    else
        "$@" >/dev/null 2>&1 &
        local pid=$!
        spinner $pid
        wait $pid
        return $?
    fi
}

# check if a binary file exists and is executable
check_binary_file_exists() {
    if [ -x "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Check if a k8s service exists in a namespace
check_k8s_service_exists_in_namespace() {
    local service_name="$1"
    local namespace="$2"

    if kubectl get service "$service_name" -n "$namespace" > /dev/null 2>&1; then
        echo "Service '$service_name' exists in namespace '$namespace'."
        return 0
    else
        echo "Service '$service_name' does not exist in namespace '$namespace'."
        return 1
    fi
}
