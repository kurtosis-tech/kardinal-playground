    #!/bin/bash

# Function to port-forward the non-dev version
forward_non_dev() {
    echo "Port-forwarding the non-dev version (voting-app-ui)..."
    kubectl port-forward -n voting-app svc/voting-app-ui 8080:80 &
    echo "Non-dev version available at: http://localhost:8080"
}

# Function to port-forward the dev version
forward_dev() {
    echo "Port-forwarding the dev version (voting-app-ui-v2)..."
    kubectl port-forward -n voting-app deploy/voting-app-ui-v2 8081:80 &
    echo "Dev version available at: http://localhost:8081"
}

# Check if the script is run with the "dev" flag
if [ "$1" == "dev" ]; then
    forward_dev
else
    forward_non_dev
    forward_dev
fi

echo "Port-forwarding initiated."