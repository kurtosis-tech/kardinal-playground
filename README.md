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

Follow these steps to explore the Kardinal Playground and experience the before → after progression:

1. 🏁 Run the startup script:
   ```
   ./scripts/startup.sh
   ```
   This will set up Docker, Minikube, Istio, Kiali, and Kardinal for you, and deploy the voting-app namespace to the Minikube cluster.

   This can take around 3 minutes 🕰️. Familiarize yourself with the repository while this happens.

   The script also supports a `--verbose` mode if you want to see what it's doing in detail.

2. 🗳 Explore the production voting app:
   - Check the "Ports" tab in the Codespaces UI
   - Look for the port labelled "voting-app-main" and open it in your browser
   - Click on the voting buttons to generate some traffic

3. 📊 Visualize the production structure in Kiali:
   - Start the Kiali dashboard:
     ```
     nohup istioctl dashboard kiali &>/dev/null &
     ```
   - Get your Codespace URL by running:
     ```
     echo "https://$(CODESPACE_NAME)-20001.app.github.dev/kiali/console/graph/namespaces/?duration=60&refresh=10000&namespaces=voting-app&idleNodes=true&layout=kiali-dagre&namespaceLayout=kiali-dagre&animation=true"
     ```
   - Open the URL provided by the command above in your browser
   - Observe the current structure of the production environment

4. 🔧 Set up the dev flow:
   ```
   kardinal create-dev-flow voting-app
   ```
   This command will handle the deployment and port forwarding for you.

5. 🧪 Interact with the dev version:
   - Check the "Ports" tab in the Codespaces UI
   - Look for the port labelled "voting-app-dev" and open it in your browser
   - Click on the voting buttons in the dev version to send traffic through it

6. 🔍 Compare the new structure in Kiali:
   - Go back to the Kiali dashboard
   - Notice the changes in the environment:
     - A dev version is now deployed
     - Dev traffic is routed to the dev version, with a database sidecar protecting the data layer
     - Prod still works independently - go to the prod version and click, it goes to the prod version and speaks to the DB directly

7. 🔄 Verify prod functionality:
   - Return to the production voting app URL
   - Confirm that it still works and interacts with the database directly

8. 🧹 Clean up the dev flow:
   ```
   kardinal delete-dev-flow voting-app
   ```

9. 🔎 Final Kiali check:
   - Return to the Kiali dashboard one last time
   - Observe that the environment has been cleaned up and returned to its original state

This guide showcases the power of Kardinal by demonstrating the seamless creation and deletion of a dev environment alongside your production setup. You'll experience firsthand how Kardinal enables isolated development without risking production data or disrupting the live environment. 🚀