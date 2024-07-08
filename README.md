# 🎡 Kardinal Playground

Welcome to the Kardinal Playground! This GitHub Codespace comes with Kardinal and all necessary tools pre-installed and ready to go. 🚀

## 🛠 Features

- 🐦 Kardinal: Our platform that allows you to dev on prod safely
- 🚙 Minikube: A tool that lets you run Kubernetes locally
- 🎛 kubectl: The command-line tool for interacting with Kubernetes clusters
- 🌐 Istio: An open-source service mesh that layers transparently onto existing distributed applications

## 🚀 Getting Started

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=818205437&skip_quickstart=true&machine=standardLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json)

1. 🏗 Create a new Codespace from this repository.
2. ⏳ Wait for the Codespace to finish setting up. This includes installing all necessary tools and starting Minikube.
3. 🎉 Once setup is complete, you're ready to start your Kardinal adventure!

## 📊 About the Voting App

The voting app is a simple application composed of two main components:

1. A Python Flask web application that allows users to vote between two options.
2. A Redis database that stores the votes.

This setup demonstrates a basic microservices architecture, making it an ideal example for showcasing Kardinal's capabilities in managing development environments.

## 🗺 Usage Guide

Follow these steps to explore the Kardinal Playground and experience the before → after progression:

1. 🏁 Run the startup script:
   ```
   ./scripts/startup.sh
   ```
   This will set up Docker, Minikube, Istio, Kardinal Manager and Kardinal CLI for you. It will
   also deploy the initial version of the voting app.

   This can take around 3 minutes 🕰️. Familiarize yourself with the repository while this happens. 

   The script also supports a `--verbose` mode if you want to see what it's doing in detail.

1. 🔗 Set up port forwarding:
   ```
   ./scripts/forward.sh
   ```

1. 🗳 Explore the production voting app:
   - Check the "Ports" tab in the Codespaces UI
   - Look for the port labelled "voting-app-prod" and open it in your browser
   - Click on the voting buttons to generate some traffic

1. 📊 Visualize the production structure in app.kardinal.dev:
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

1. 🔍 Compare the new structure in the app.kardinal.dev:
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
    ./scripts/forward.sh
    ```
    Run this one last time to update the port forwarding.

1. 🔎 Final graph check
    - Return to the dashboard one last time
    - Observe that the environment has been cleaned up and returned to its original state, with only the "prod" namespace visible

This guide showcases the power of Kardinal by demonstrating the seamless creation and deletion of a dev environment alongside your production setup. You'll experience firsthand how Kardinal enables isolated development without risking production data or disrupting the live environment in the "prod" namespace. 🚀

## 🔗 Port Forwarding Explanation

We're using port forwarding in this Codespace setup to make the various services accessible to you. Since the Minikube cluster is running inside the Codespace, we need to forward specific ports to allow you to interact with the applications and dashboards through your browser. This is why you'll see multiple forwarded ports in the "Ports" tab of the Codespace UI.

If you encounter any issues with port forwarding, you can reset it by running:
```
./scripts/forward.sh
```

## ⏩ What's Next?

We are working with a small but selective set of initial users, join the beta [here](https://kardinal.dev/?utm_source=github). Or even better email us at `hello@kardinal.dev`.

## 🐛 Issues

If you run into any issues with this playground please create an issue here or email us at `hello@kardinal.dev`.

If you are encountering any issue with the port forwards, simply use `./scripts/forward.sh` to reset the port forwarding.
