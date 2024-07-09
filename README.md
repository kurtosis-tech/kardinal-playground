# 🎡 Kardinal Playground

Welcome to the Kardinal Playground! This codespace contains a demo showing how you can safely test new features in production without risking downtime using Kardinal. 🚀 It takes about 5 minutes, 3 of which are just waiting for the setup script to complete.


In this demo, you will:
1. Set up a Kubernetes cluster with a demo voting app installed on it (3 minutes)
2. Visualize your production cluster using the Kardinal Dashboard (30 seconds)
3. Use Kardinal to set up a lightweight "dev environment" inside of your production cluster so you can test on production data (30 seconds)
4. Visualize your cluster in the Kardinal Dashboard again, to see how the Kardinal "dev environment" is structured (30 seconds)

## 🛠 Features

- 🐦 Kardinal: Our developer tool for safely developing in prod

## 🚀 Getting Started

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=818205437&skip_quickstart=true&machine=standardLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json)

1. 🏗 Create a new Codespace from this repository.
2. 🎉 Once setup is complete, run through the steps in the "Usage Guide" section

## 📊 About the Voting App

The voting app is a simple application composed of two main components:

1. A Python Flask web application that allows users to vote between two options.
2. A Redis database that stores the votes.

This setup demonstrates a basic microservices architecture, making it an ideal example for showcasing Kardinal's capabilities in managing development environments.

## 🗺 Usage Guide

Follow these steps to explore the Kardinal Playground.

1. 🏁 Run the startup script:
   ```
   ./scripts/startup.sh
   ```
   This will set up Docker, Minikube, Istio, Kardinal Manager and Kardinal CLI for you. It will
   also deploy the initial version of the voting app.

   This can take around 3 minutes 🕰️.

1. 🔗 Set up port forwarding:
   ```
   ./scripts/forward.sh prod
   ```

1. 🗳 Explore the production voting app:
   - Check the "Ports" tab in the Codespaces UI
   - Look for the port labelled "voting-app-prod" and open it in your browser
   - Click on the voting buttons to generate some traffic
  
   **Note**: Codespaces port forwarding can be flaky. If you immediately click on the toast that pops up when a port is fowarded, it can be too fast and the port tunnel will shut down. If that happens, just run `./scripts/forward.sh` to set up the forwarding again. Then, don't click on the toast - instead, let it run, wait a tick, and open the port in the "ports" tab.

1. 📊 Visualize the production structure on app.kardinal.dev:
   - Get your Kardinal URL by running:
     ```
     echo "https://app.kardinal.dev/$(cat ~/.local/share/kardinal/fk-tenant-uuid)/traffic-configuration"
     ```
   - Open the URL provided by the command above in your browser
   - Observe the current structure of the production environment

1. 🔧 Create the dev flow:
   ```
   kardinal flow create voting-app-ui voting-app-ui-dev -d voting-app-demo/compose.yml
   ```
   This command sets up a development version of the voting app alongside the production version.

1. 🔄 Update port forwarding:
   ```
   ./scripts/forward.sh
   ```
   Run this again to ensure all new services are properly forwarded.

1. 🧪 Interact with the dev version:
   - Check the "Ports" tab in the Codespaces UI
   - Look for the port labelled "voting-app-dev" and open it in your browser
   - Click on the voting buttons in the dev version to send traffic through it
   
   **Note**: Codespaces port forwarding can be flaky. If you immediately click on the toast that pops up when a port is fowarded, it can be too fast and the port tunnel will shut down. If that happens, just run `./scripts/forward.sh` to set up the forwarding again. Then, don't click on the toast - instead, let it run, wait a tick, and open the port in the "ports" tab.   


1. 🔍 Compare the new structure on app.kardinal.dev:
   - Go back to the dashboard
   - Notice the changes in the environment:
     - A dev version is now deployed in the same namespace
     - Dev traffic is routed to the dev version, with a database sidecar protecting the data layer
     - Prod still works independently in the same namespace - go to the prod version and click, it goes to the prod version and speaks to the DB directly

1. 🔄 Verify prod functionality:
    - Return to the production voting app URL
    - Confirm that it still works and interacts with the database directly in the "prod" namespace

1. 🧹 Clean up the dev flow:
    ```
    kardinal flow delete -d voting-app-demo/compose.yml
    ```
    This command removes the development version of the app.

1. 🔄 Final port forwarding update:
    ```
    ./scripts/forward.sh prod
    ```
    Run this one last time to update the port forwarding.

1. 🔎 Final dashboard check
    - Return to the dashboard one last time
    - Observe that the environment has been cleaned up and returned to its original state, with only the "prod" services visible.

This guide showcases the power of Kardinal by demonstrating the seamless creation and deletion of a dev environment alongside your production setup. You'll experience firsthand how Kardinal enables isolated development without risking production data or disrupting the live environment.🚀

## 🔗 Port Forwarding Explanation

We're using port forwarding in this Codespace setup to make the various services accessible to you. Since the Minikube cluster is running inside the Codespace, we need to forward specific ports to allow you to interact with the applications and dashboards through your browser. This is why you'll see multiple forwarded ports in the "Ports" tab of the Codespace UI.

Codespaces port forwarding can be flaky. If you immediately click on the toast that pops up when a port is fowarded, it can be too fast and the port tunnel will shut down. If that happens, just run `./scripts/forward.sh` to set up the forwarding again. Then, don't click on the toast - instead, let it run, wait a tick, and open the port in the "ports" tab.


If you encounter any issues with port forwarding, you can reset it by running:
```
./scripts/forward.sh
```

## ⏩ What's Next?

We are working with a small but selective set of initial users, join the beta [here](https://kardinal.dev/?utm_source=github). Or even better email us at `hello@kardinal.dev`.

## 🐛 Issues

If you run into any issues with this playground please create an issue here or email us at `hello@kardinal.dev`.

If you are encountering any issue with the port forwards, simply use `./scripts/forward.sh` to reset the port forwarding.
