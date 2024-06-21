# Kardinal Playground

This repository contains a GitHub Codespace with Kardinal up and running out of the box

## Features

- Kardinal
- Minikube
- kubectl
- Istio
- Kiali


## Getting Started

1. Create a new Codespace from this repository.
2. Wait for the Codespace to finish setting up. This includes installing all necessary tools and starting Minikube.
3. Once setup is complete, you can start using kubectl, istioctl, and other installed tools.

## Usage

- Minikube dashboard is automatically started and can be accessed via port forwarding.
- Kiali dashboard is also started and can be accessed for observing your Istio service mesh.
- The hostnames `voting-app.localhost` and `dev.voting-app.localhost` are automatically added to `/etc/hosts`.