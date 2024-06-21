FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install minikube
RUN curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
    install minikube-linux-amd64 /usr/local/bin/minikube

# Install Istio
RUN curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.1 sh - && \
    mv istio-1.22.1/bin/istioctl /usr/local/bin/ && \
    rm -rf istio-1.22.1

# Copy scripts
COPY scripts/install.sh /usr/local/bin/install.sh
COPY scripts/startup.sh /usr/local/bin/startup.sh

RUN chmod +x /usr/local/bin/install.sh /usr/local/bin/startup.sh