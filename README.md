# 🎡 Kardinal Playground

## Disclaimer: This project is no longer maintained.

Welcome to the Kardinal Playground! This walkthrough shows how you can test new features in ultra-lightweight development environments using Kardinal. 🚀

This repo is designed to run in Github Codespaces. It has 5 steps and takes 5 minutes. 3 of those minutes are just waiting for the startup script to run in Codespaces.

In this demo, you will:

1. Set up a Kubernetes cluster with a demo online boutique app installed on it (3 minutes)
2. Visualize your stable, staging cluster using the Kardinal Dashboard (30 seconds)
3. Use Kardinal to set up a lightweight "dev environment" inside your cluster, so you can quickly and efficiently test changes (30 seconds)
4. Visualize your cluster in the Kardinal Dashboard again, to see how the Kardinal "dev environment" is structured (30 seconds)
5. Clean up the dev flow and return the cluster to normal state (15 seconds)

## 🚀 Codespace

Create a new Codespace from this repository using the button below. The default settings for the Codespace will work just fine. Once setup is complete, run through the steps in the "Usage Guide" section.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=818205437&skip_quickstart=true&machine=standardLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json)

## 🗺 Usage Guide

Follow these steps to explore the Kardinal Playground.

1. 🏁 Run the startup script:

   ```bash
   ./scripts/startup.sh
   ```

   This will set up Docker, Minikube, Istio, Kardinal Manager, Kardinal CLI, and nginx for you. It will
   also deploy the initial version of the online boutique app.

   This can take around 3 minutes 🕰️.

2. 🛍️ Explore the main online boutique deployment:

   Run the following command, to view the demo from your browser:
   
   ```bash
   kardinal gateway baseline
   ```

   This command forwards the main demo application port from within Codespaces to a URL you can access

   Now, explore the application:

   - Click the URL provided by gateway `http://localhost:9060`
   - Browse through the online store and add items to your cart
   - To see your application architecture, get your dashboard URL by running the following:
     ```bash
     echo "https://app.kardinal.dev/$(cat ~/.local/share/kardinal/fk-tenant-uuid)/traffic-configuration"
     ```
   - Open the URL provided by the command above in your browser
   - Observe the current structure of the deployment

3. 🔧 Create the first dev flow:

   Let's deploy a dev version of the frontend that is adding a more bold style to the website, this modification is contained into a single `frontend` image:

   ```bash
   kardinal flow create frontend kurtosistech/frontend:demo-frontend
   ```

   This command sets up a development version of the frontend alongside the main version. It will output a URL, but it's not yet accessible because it's inside the Codespace.

   - To interact with the dev version, first stop your previous gateway (if it's still running). Currently, you can only run one gateway at a time in this demo.
   - Copy the flow-id from the previous command (it should look like `dev-[a-zA-Z0-9]`)
   - Run the following to forward the dev demo application port from within Codespaces to a URL you can access
     ```bash
     kardinal gateway <flow-id>
     ```
   - Access the dev frontend from the forwarded port
   - Notice the dev frontend advertises "hottest products" now
   - Browse through the store and add items to your cart in the dev version

4. 🧹 Clean up the dev flow:

   ```bash
   kardinal flow delete <flow_id>
   ```

   This command removes the development version of the app.

    - Return to the dashboard one last time
    - Observe that the environment has been cleaned up and returned to its original state, with only the main services visible.
    - Return to the main online boutique URL (the first nginx URL)
    - Confirm that it still works and has not been impacted by the development workflow

5. 🔧 Create a second and more complex dev flow:

   Now our demo website is preparing for a big sale, we need to add a new feature to both the backend and the frontend to handle the new sale. This feature is contained into 2 images: `frontend` and `productcatalogservice`.
   We can rely on support for multiple services to coordinate the deployment in a single flow. Using the flag `-s`, we can include multiple services and images:

   ```bash
   kardinal flow create frontend kurtosistech/frontend:demo-on-sale -s productcatalogservice=kurtosistech/productcatalogservice:demo-on-sale
   ```

   This command sets up a development version of the frontend alongside the main version. It will output a URL, but it's not yet accessible because it's inside the Codespace.

   - To interact with the dev version, first stop your previous gateway (if it's still running). Currently, you can only run one gateway at a time in this demo.
   - Copy the flow-id from the previous command (it should look like `dev-[a-zA-Z0-9]`)
   - Run the following to forward the dev demo application port from within Codespaces to a URL you can access
     ```bash
     kardinal gateway <flow-id>
     ```
   - Access the dev frontend from the forwarded port
   - Notice how two items are already in the cart, as the dev database is configured to be seeded with some dev data
   - Browse through the store and add items to your cart in the dev version

6. 🔍 Compare the new structure on app.kardinal.dev:

   - Go back to the Kardinal dashboard
   - Notice the changes in the environment:
     - A dev version of the frontend is now deployed in the same namespace
     - Dev traffic is routed to the dev version of the frontend
     - The main version still works independently in the same namespace

7. 🧹 Clean up the dev flow:

   ```bash
   kardinal flow delete <flow_id>
   ```

8. 🔧 Create a third dev flow to intercept the traffic to a local port with [Telepresence](https://www.telepresence.io/) and test a new change in the UI without having to rebuild and redeploy the container in the cluster.

   - Execute the following script to install the Telepresence CLI and the Traffic Manager's pod in the cluster.
     ```bash
     ./scripts/telepresence.sh
     ```
     This script will also start the Telepresence daemon in the foreground, so make sure to add a new terminal for the next commands.
   - Create a dev flow for the frontend service and take note of the flow-id created
     ```bash
     kardinal flow create frontend kurtosistech/frontend:demo-frontend
     ```
   - As already see, to interact with the dev version, first stop your previous gateway (if it's still running).
   - Run the following to forward the dev demo application port from within Codespaces to a URL you can access
     ```bash
     kardinal gateway <flow-id>
     ```
   - Access the dev frontend from the forwarded port
   - Make a change in the frontend `home` template. Edit the file inside `./src/frontend/templates/home.html`
     - For example, you can replace the line `<h3>Hot Products</h3>` with `<h3>Hot Products - Testing intercepts</h3>`
   - Leave the terminal were you run the latest gateway command and create a new one to run the next commands
   - Now you can start the edited frontend version in the host
   ```bash
   ./scripts/run-frontend.sh
   ```
   - This will open a new port (8070 in this example) that you can access to see the new version of the frontend
   - Leave the frontend app running in the terminal and create a new terminal to run the next commands
   - Execute the `kardinal flow telepresence-intercept` command to send the traffic to the frontend version running in the host
   ```bash
   kardinal flow telepresence-intercept <flow_id> frontend 8070
   ```
   - Wait for a couple of second and go back to the browser's tab where the dev flow app is running and refresh the browser to check the intercept
   - You should see that the UI has been modified showing the changes you made in the `home` template
   - The intercept makes it possible to send the cluster's traffic to the app running in the host and, it's able to connect to the other services inside the cluster because it was able to connect to the cluster's network with Telepresence.
   - Now you can leave the intercept
   ```bash
   telepresence leave frontend-<flow_id>
   ```
   - Go back to the open tab and check that the UI is back to the previous version without your changes

9. 🧹 Clean up the dev flow:

   ```bash
   kardinal flow delete <flow_id>
   ```

This guide showcases the power of Kardinal by demonstrating the seamless creation and deletion of a dev environment alongside your main, stable setup. You'll experience firsthand how Kardinal enables isolated development without risking stability of a shared cluster, or disrupting the live environment. 🚀

## 🧠 Advanced

Kardinal also has supports for `templates`. Templates are overrides on the base manifest that allow you to configure annotations different from the base manifest.
[Template Example](/template.yaml) is one such template that does the following

1. It adds an extra item to the database compared to the base manifest and it shows how the quantity field is configurable; when used with [example arguments file](/template_args.yaml) an extra item is added to the cart with quantity set to 3. If you don't supply args the quantity defaults to 1.
1. It adds an extra annotation `kardinal.dev.service/shared: "true"`. Any flow using this template uses a `shared` instance of Postgres allowing you to use the same instance across flows; making it more resource efficient.

While the plugin annotation replaces any existing plugin annotation on the Postgres service; the `shared` annotation is additive to the base manifest.

To create a template use the following command

```bash
kardinal template create extra-item-shared --template-yaml ./template.yaml --description "Extra item and postgres is shared"
```

You can use the alias `-t` for the `--template-yaml` flag and `-d` for the `--description` flag.

To use the template with a flow

```bash
kardinal flow create frontend kurtosistech/frontend:demo-frontend  --template-args ./template_args.yaml --template extra-item-shared
```

You can use the alias `-a` for the `--template-args` flag and `-t` for the `--template` flag.

## 🔗 Port Forwarding Explanation

We're using port forwarding in combination with a proxy in this Codespace setup to make the various services accessible to you. We use Codespaces to forward URLs over the internet but add an nginx proxy to set the right hostname to hit the right lightweight environment

If you encounter any issues with port forwarding or nginx, you can reset it by running:

```bash
# make sure all pods are running and 2/2
kubectl get pods -n baseline
kardinal gateway <flow-id>
```

## 🐘 Neon PostgreSQL Demo

If you'd like to try the demo with Neon instead of vanilla Postgres, you can do so by following these steps:

1. Change to the PostgreSQL demo directory:
   ```bash
   cd neon-postgres-demo
   ```
2. Follow the instructions in the README file in that directory.

This alternative demo showcases Kardinal's ability to handle stateful services managed outside the cluster by leveraging Kardinal [plugins](https://kardinal.dev/docs/concepts/plugins).
