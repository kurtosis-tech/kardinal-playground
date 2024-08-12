# 🎡 Kardinal Playground

Welcome to the Kardinal Playground! This walkthrough shows how you can test new features in ultra-lightweight development environments using Kardinal. 🚀

In this demo, you will:
1. Set up a Kubernetes cluster with a demo online boutique app installed on it that stores data in an external Postgres [Neon DB](neon.tech) (4 minutes)
2. Visualize your production cluster using the Kardinal Dashboard (30 seconds)
3. Use Kardinal to set up a lightweight "dev environment" inside of your production cluster so you can test on production data (30 seconds)
4. Visualize your cluster in the Kardinal Dashboard again, to see how the Kardinal "dev environment" is structured (30 seconds)

Note: make sure you are in the `neon-postgres-demo` directory while following this demo!

## 🛠 Features

- 🐦 Kardinal: Our developer tool for safely developing in prod
- 📀 Neon: A serverless Postgres platform that supports branching

## 🚀 Getting Started

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=818205437&skip_quickstart=true&machine=standardLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json)

1. 🏗 Create a new Codespace from this repository.
2. 🎉 Once setup is complete, run through the steps in the "Usage Guide" section.

## 📊 About the Online Boutique Store App with Neon DB

While the Online Boutique Store demo at the base of the repo connects to a Postgres DB managed in the cluster, this app is configured to rely on a Neon Postgres DB. 

Anytime Kardinal creates a dev flow that requires creating a "dev" version of the Neon DB, Kardinal will utilize the [neon-db-plugin](https://github.com/kurtosis-tech/neondb-plugin). This plugin contains logic to create a new Neon branch, and update any dev versions of services that depend on the Neon DB to point to the dev branch. 

To learn more about how Kardinal's plugin mechanism works, refer to or [plugin](https://kardinal.dev/docs/concepts/plugins) documentation. For now, let's see how this works in action!

## 🗺 Usage Guide

Follow these steps to explore the Kardinal Playground.

1. 🏁 Set up Neon and run the startup script:

   a. First, you'll need to set up a Neon account and database:
      - Go to https://neon.tech and sign up for an account if you don't have one.
      - Create a new project in Neon with a database named `cart`.
      - In your project, create a new branch (this will be your main branch).

   b. Open the file `obd-demo.yaml` in this directory and fill in the following variables:
      - NEON_API_KEY: Your Neon API key (found in your Neon account settings)
      - NEON_PROJECT_ID: The ID of your Neon project (visible in the project URL)
      - NEON_FORK_FROM_BRANCH_ID: The ID of the main branch you created
      - POSTGRES: The connection string for your Neon database (found in the connection details of your branch)

   c. Run the startup script:
      ```
      ./scripts/startup.sh
      ```
      This will set up Docker, Minikube, Istio, Kardinal Manager and Kardinal CLI for you. It will
      also deploy the initial version of the voting app.

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
   - Refer to your Neon console dashboard to verify that the application is connected to your database and data is reflected in the main branch!

3. 🔧 Create the dev flow:
   ```
   kardinal flow create frontend leoporoli/newobd-frontend:dev
   ```
   This command sets up a development version of the frontend alongside the main version. Additionally, it will create any required dev versions of services that are downstream. In this case the frontend depends on the cartservice, that depends on the Neon DB. In order to isolate data from our prod flow, we'll need to create dev version of the cartservice and Neon DB. 
   
   The command will output a url, but it's not yet accessible because it's inside the Codespace.

   - To interact with the dev version, first stop your previous gateway (if it's still running). Currently you can only run one gateway at a time in this demo.
   - Copy the flow-id from the previous command (it should look like `dev-[a-zA-Z0-9]`)
   - Run the following to forward the dev demo application port from within Codespaces to a URL you can access
     ```
     kardinal gateway <flow-id>
     ```
   - Access the dev frontend from the forwarded port
   - Notice how two items are already in the cart, as the dev branch is configured to be branched off the main branch
   - Browse through the store and add items to your cart in the dev version
   - Refer to your Neon console dashboard to verify that a new branch was created and any cart updates are now reflected in the branched DB!

4. 🔍 Compare the new structure on app.kardinal.dev:
   - Go back to the Kardinal dashboard
   - Notice the changes in the environment:
     - A dev version of the frontend is now deployed in the same namespace
     - Dev versions of all downstream services are deployed including the Free Currency API, cartservice, and Neon DB!
     - Dev traffic is routed to the dev version of the frontend and through corresponding dev versions of downstream services
     - The main version still works independently in the same namespace

1. 🔄 Verify prod functionality:
    - Return to the production voting app URL (ending with -8090)
    - Confirm that it still works and interacts with the database directly in the "prod" namespace

5. 🧹 Clean up the dev flow:
    ```
    kardinal flow delete <flow_id>
    ```
    This command removes the development version of the app.
   
    - Return to the dashboard one last time
    - Observe that the environment has been cleaned up and returned to its original state, with only the main services visible.
    - Return to the main online boutique URL (the first nginx URL)
    - Confirm that it still works and has not been impacted by the development workflow
    - Refer to your Neon console dashboard to see that the forked dev branch has been cleaned up

This guide showcases the power of Kardinal by demonstrating the seamless creation and deletion of a dev environment alongside your production setup. Furthermore, it showcases how Kardinal can effectively integrate with services outside the your cluster in a way that maintains isolation for your dev environments. You'll experience firsthand how Kardinal enables isolated development without risking production data or disrupting the live environment.🚀

## 🔗 Port Forwarding Explanation

We're using port forwarding in combination with a proxy in this Codespace setup to make the various services accessible to you. We use Codespaces to forward URLs over the internet but add an nginx proxy to set the right hostname to hit the right lightweight environment

If you encounter any issues with port forwarding or nginx, you can reset it by running:
```
# make sure all pods are running and 2/2
kubectl get pods -n prod
kardinal gateway <flow-id>
```

## 📘 About Neon and Required Fields

Neon is a fully managed serverless PostgreSQL database service. It offers features like automatic scaling, branching, and point-in-time recovery. In this demo, we're using Neon to provide the database backend for our voting app.

Here's what each field represents:

1. NEON_API_KEY: This is your personal API key for authenticating with Neon's services. It allows the demo to interact with your Neon account programmatically.

2. NEON_PROJECT_ID: Each project in Neon has a unique identifier. This ID is used to specify which project the demo should work with.

3. NEON_FORK_FROM_BRANCH_ID: Neon allows you to create branches of your database, similar to git branches. The main branch ID refers to the primary branch of your database that the production version of the app will use, so we'll fork off of that when creating dev versions.

4. POSTGRES: This is the connection string for your Neon database. It includes all the necessary information (host, port, database name, username, password) for the application to connect to your database.

By using Neon in this demo, we're showcasing how Kardinal can work with modern, cloud-native database services, allowing for features like database branching which can be very useful in development and testing scenarios. The instant branching capability of Neon, combined with Kardinal's traffic management, enables developers to work with isolated copies of production data, make changes, and test new features without any risk to the live environment.

## ⏩ What's Next?

We are working with a small but selective set of initial users, join the beta [here](https://kardinal.dev/?utm_source=github). Or even better email us at `hello@kardinal.dev`.

## 🐛 Issues

If you run into any issues with this playground please create an issue here or email us at `hello@kardinal.dev`.

If you are encountering any issue with the port forwards, simply use `kardinal gateway prod` to reset the port forwarding.
