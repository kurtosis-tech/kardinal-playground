# 🎡 Kardinal Playground

Welcome to the Kardinal Playground! This walkthrough shows how you can test new features in ultra-lightweight development environments using Kardinal. 🚀 

This repo is designed to run in Github Codespaces. It has 5 steps and takes 5 minutes. 3 of those minutes are just waiting for the startup script to run in Codespaces.

In this demo, you will:

1. Set up a Kubernetes cluster with a demo online boutique app installed on it (3 minutes)
2. Visualize your stable, staging cluster using the Kardinal Dashboard (30 seconds)
3. Use Kardinal to set up a lightweight "dev environment" inside of your cluster so you can quickly and efficiently test changes (30 seconds)
4. Visualize your cluster in the Kardinal Dashboard again, to see how the Kardinal "dev environment" is structured (30 seconds)
5. Clean up the dev flow and return the cluster to normal state (15 seconds)

## 🚀 Codespace

Create a new Codespace from this repository using the button below. The default settings for the Codespace will work just fine. Once setup is complete, run through the steps in the "Usage Guide" section.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=818205437&skip_quickstart=true&machine=standardLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json)


## 🗺 Usage Guide

Follow these steps to explore the Kardinal Playground.

1. 🏁 Run the startup script:
   ```
   ./scripts/startup.sh
   ```
   This will set up Docker, Minikube, Istio, Kardinal Manager, Kardinal CLI, and nginx for you. It will
   also deploy the initial version of the online boutique app.

   This can take around 3 minutes 🕰️.

2. 🛍️ Explore the main online boutique deployment:
   ```
   kardinal gateway prod
   ```
   This command forwards the main demo application port from within Codespaces to a URL you can access

   Now, explore the application:
   - Click the URL provided by gateway `http://localhost:9060`
   - Browse through the online store and add items to your cart
   - To see your application architecture, get your dashboard URL by running the following:
     ```
     echo "https://app.kardinal.dev/$(cat ~/.local/share/kardinal/fk-tenant-uuid)/traffic-configuration"
     ```
   - Open the URL provided by the command above in your browser
   - Observe the current structure of the deployment

3. 🔧 Create the dev flow:
   ```
   kardinal flow create frontend leoporoli/newobd-frontend:dev
   ```
   This command sets up a development version of the frontend alongside the main version. It will output a URL, but it's not yet accessible because it's inside the Codespace.

   - To interact with the dev version, copy the flow-id from the previous command (it should look like `dev-[a-zA-Z0-9]`)
   - Run the following to forward the dev demo application port from within Codespaces to a URL you can access
     ```
     kardinal gateway <flow-id>
     ```
   - Access the dev frontend from the forwarded port
   - Notice how two items are already in the cart, as the dev database is configured to be seeded with some dev data
   - Browse through the store and add items to your cart in the dev version

4. 🔍 Compare the new structure on app.kardinal.dev:
   - Go back to the Kardinal dashboard
   - Notice the changes in the environment:
     - A dev version of the frontend is now deployed in the same namespace
     - Dev traffic is routed to the dev version of the frontend
     - The main version still works independently in the same namespace

5. 🧹 Clean up the dev flow:
    ```
    kardinal flow delete <flow_id>
    ```
    This command removes the development version of the app.
   
    - Return to the dashboard one last time
    - Observe that the environment has been cleaned up and returned to its original state, with only the main services visible.
    - Return to the main online boutique URL (the first nginx URL)
    - Confirm that it still works and has not been impacted by the development workflow

This guide showcases the power of Kardinal by demonstrating the seamless creation and deletion of a dev environment alongside your main, stable setup. You'll experience firsthand how Kardinal enables isolated development without risking stability of a shared cluster, or disrupting the live environment. 🚀

## 🔗 Port Forwarding Explanation

We're using port forwarding in combination with a proxy in this Codespace setup to make the various services accessible to you. We use Codespaces to forward URLs over the internet but add an nginx proxy to set the right hostname to hit the right lightweight environment

If you encounter any issues with port forwarding or nginx, you can reset it by running:
```
# make sure all pods are running and 2/2
kubectl get pods -n prod
kardinal gateway <flow-id>
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
