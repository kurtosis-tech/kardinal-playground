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
   ./scripts/startup.sh
   ```
   Wait for it to complete. For verbose output, use `./scripts/startup.sh --verbose`.

2. 🚀 Forward the prod version of the voting app (ideally in a new terminal tab):
   ```
   ./scripts/forward.sh
   ```

3. 🏗 Build the necessary images:
   ```
   minikube image build -t voting-app-ui -f ./Dockerfile ./voting-app-demo/voting-app-ui/
   minikube image build -t voting-app-ui-v2 -f ./Dockerfile-v2 ./voting-app-demo/voting-app-ui/
   ```

4. 🗳 Play with voting-app-v1 (prod version)
   - Check the "Ports" tab in the Codespaces UI
   - Look for the port labelled "voting-app-v1" and open it in your browser

5. 🔧 Set up the dev flow:
   ```
   kardinal create-dev-flow voting-app
   ```

6. 🚀 Forward the dev version of the voting app (ideally in a new terminal tab):
   ```
   ./scripts/forward.sh dev
   ```
   ⚠️ if the forwarded port doesn't open, run this again.

7. 🧪 Play with voting-app-v2 (dev version)
   - Check the "Ports" tab in the Codespaces UI
   - Look for the port labelled "voting-app-v2" and open it in your browser
   - This version talks to a proxied Redis with prod data in real time!

8. 🧹 Clean up when you're done:
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