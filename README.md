# 🎡 Kardinal Playground

Welcome to the Kardinal Playground! This codespace contains a demo showing how you can safely test new features in ultra-lightweight development environments using Kardinal. 🚀 It takes about 5 minutes, 3 of which are just waiting for the setup script to complete.

> **Note**: Want to try the demo with Neon PostgreSQL instead of vanilla PostgresSQL? Check out the [Neon PostgreSQL Demo](#-neon-postgresql-demo) section below!

In this demo, you will:
1. Set up a Kubernetes cluster with a demo online boutique app installed on it (3 minutes)
2. Visualize your stable, staging cluster using the Kardinal Dashboard (30 seconds)
3. Use Kardinal to set up a lightweight "dev environment" inside of your cluster so you can quickly and efficiently test changes (30 seconds)
4. Visualize your cluster in the Kardinal Dashboard again, to see how the Kardinal "dev environment" is structured (30 seconds)

## 🛠 Features

- 🐦 Kardinal: Our developer tool for spinning up ultra-lightweight development environments in Kubernetes

## 🚀 Getting Started

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=818205437&skip_quickstart=true&machine=standardLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json)

1. 🏗 Create a new Codespace from this repository.
2. 🎉 Once setup is complete, run through the steps in the "Usage Guide" section

## 📊 About the Online Boutique App

The Online Boutique app is a cloud-native microservices demo application. It's a web-based e-commerce app where users can browse items, add them to the cart, and purchase them.

This setup demonstrates a microservices architecture, making it an ideal example for showcasing Kardinal's capabilities in managing development environments.

## 🗺 Usage Guide

Follow these steps to explore the Kardinal Playground.

1. 🏁 Run the startup script:
   ```
   ./scripts/startup.sh
   ```
   This will set up Docker, Minikube, Istio, Kardinal Manager, Kardinal CLI, and nginx for you. It will
   also deploy the initial version of the online boutique app.

   This can take around 3 minutes 🕰️.

2. 🔗 Set up port forwarding and start nginx:
   ```
   ./scripts/forward.sh
   ```
   This script will set up port forwarding and start nginx. Use the codespaces URL that is printed on the screen.

3. 🛍️ Explore the main online boutique deployment:
   - Use the nginx URL provided by the forward.sh script
   - Browse through the online store and add items to your cart to generate some traffic
   - This might take a few seconds and a few retries as sometimes the local port forwarding takes a few seconds to come up

4. 📊 Visualize the application structure on app.kardinal.dev:
   - Get your Kardinal URL by running:
     ```
     echo "https://app.kardinal.dev/$(cat ~/.local/share/kardinal/fk-tenant-uuid)/traffic-configuration"
     ```
   - Open the URL provided by the command above in your browser
   - Observe the current structure of the deployment

5. 🔧 Create the dev flow:
   ```
   kardinal flow create frontend leoporoli/newobd-frontend:dev
   ```
   This command sets up a development version of the frontend alongside the main version.

6. 🌐 Set up nginx for the dev instance:
   - From the output of the previous command, copy the host value (it should look like `dev-[a-zA-Z0-9]+.app.localhost`)
   - Run a new nginx instance with this host:
     ```
     ./scripts/forward.sh [your-dev-host-value]
     ```
   - Note the new codespaces URL

7. 🧪 Interact with the dev version:
   - Use the nginx nginx URL to access your dev instance of the online boutique
   - Notice how two items are already in the cart as we seeded the dev database for you
   - Browse through the store and add items to your cart in the dev version

8. 🔍 Compare the new structure on app.kardinal.dev:
   - Go back to the dashboard
   - Notice the changes in the environment:
     - A dev version of the frontend is now deployed in the same namespace
     - Dev traffic is routed to the dev version of the frontend
     - The main version still works independently in the same namespace

9. 🌐 Set up nginx for the prod instance:
   - Run a new nginx instance with this host:
     ```
     ./scripts/forward.sh
     ```
   - Note the new codespaces URL     

10. 🔄 Verify main deployment functionality:
    - Return to the main online boutique URL (the first nginx URL)
    - Confirm that it still works and has not been impacted by the development workflow

11. 🧹 Clean up the dev flow:
    ```
    kardinal flow delete
    ```
    This command removes the development version of the app.

11. 🔎 Final dashboard check
    - Return to the dashboard one last time
    - Observe that the environment has been cleaned up and returned to its original state, with only the main services visible.

This guide showcases the power of Kardinal by demonstrating the seamless creation and deletion of a dev environment alongside your main, stable setup. You'll experience firsthand how Kardinal enables isolated development without risking stability of a shared cluster, or disrupting the live environment. 🚀

## 🔗 Port Forwarding and nginx Explanation

We're using port forwarding in combination with nginx in this Codespace setup to make the various services accessible to you. We use Codespaces to forward URLs over the internet but add an nginx proxy to set the right hostname to hit the right lightweight environment

If you encounter any issues with port forwarding or nginx, you can reset it by running:
```
./scripts/forward.sh
```

## 🐘 Neon PostgreSQL Demo

If you'd like to try the demo with Neon instead of vanilla Postgres, you can do so by following these steps:

1. Change to the PostgreSQL demo directory:
   ```
   cd postgres-demo
   ```
2. Follow the instructions in the README file in that directory.

This alternative demo showcases Kardinal's capabilities with a different database technology.

## ⏩ What's Next?

We are working with a small but selective set of initial users, join the beta [here](https://kardinal.dev/?utm_source=github). Or even better email us at `hello@kardinal.dev`.

## 🐛 Issues

If you run into any issues with this playground please create an issue here or email us at `hello@kardinal.dev`.

If you are encountering any issue with the port forwards or nginx, simply use `./scripts/forward.sh` to reset the setup.
