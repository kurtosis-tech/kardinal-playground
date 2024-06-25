# 🎡 Kardinal Playground

Welcome to the Kardinal Playground! This GitHub Codespace comes with Kardinal and all necessary tools pre-installed and ready to go. 🚀

## 🛠 Features

- 🐦 Kardinal
- 🚙 Minikube
- 🎛 kubectl
- 🌐 Istio
- 📊 Kiali

## 🚀 Getting Started

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=818205437&skip_quickstart=true&machine=standardLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json)

1. 🏗 Create a new Codespace from this repository.
2. ⏳ Wait for the Codespace to finish setting up. This includes installing all necessary tools and starting Minikube.
3. 🎉 Once setup is complete, you're ready to start your Kardinal adventure!

## 🗺 Usage Guide

Follow these steps to explore the Kardinal Playground:

1. 🏁 Run the startup script:
   ```
   source ./scripts/startup.sh
   ```
   This will setup Docker, Minikube, Istio, Kiali and Kardinal for you!

   It will also deploy the voting-app namespace to the Minikube cluster.

   This can take around 3 minutes 🕰️! Familiarize yourself with the repository while this happens

   The script also supports a `--verbose` mode if  you want to see what its doing in detail.

2. 🚀 Forward the prod version of the voting app (ideally in a new terminal tab):
   ```
   ./scripts/forward.sh
   ```

3. 🗳 Play with voting-app-v1 (prod version)
   - Check the "Ports" tab in the Codespaces UI
   - Look for the port labelled "voting-app-v1" and open it in your browser

4. 🔧 Set up the dev flow:
   ```
   kardinal create-dev-flow voting-app
   ```

5. 🚀 Forward the dev version of the voting app (ideally in a new terminal tab):
   ```
   ./scripts/forward.sh dev
   ```
   ⚠️ if the forwarded port doesn't open, run this again.

6. 🧪 Play with voting-app-v2 (dev version)
   - Check the "Ports" tab in the Codespaces UI
   - Look for the port labelled "voting-app-v2" and open it in your browser
   - This version talks to a proxied Redis with prod data in real time!

7. 🧹 Clean up when you're done:
   ```
   kardinal delete-dev-flow voting-app
   ```

## 🔍 Exploring Further

- 📊 Launch the Minikube dashboard:
  ```
  minikube dashboard
  ```
  This will start the dashboard and open it in your default web browser.

- 📈 Access the Kiali dashboard:
  ```
  istioctl dashboard kiali
  ```
  This command will start the Kiali dashboard and provide a URL to access it.

- 🕸 Viewing the Network Graph in Kiali:
  1. Once in the Kiali dashboard, navigate to the "Graph" section in the left sidebar.
  2. In the namespace dropdown, select "voting-app".
  3. You'll now see a visual representation of the network traffic and relationships between services in the voting-app namespace.
  4. Experiment with different graph options to gain insights into your service mesh!

These dashboards provide powerful visualization and management tools for your Kubernetes cluster and Istio service mesh. Happy exploring in the Kardinal Playground! 🎉🚀