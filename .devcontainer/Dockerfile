FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu

# Install Istio
RUN curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.1 sh - && \
    mv istio-1.22.1/bin/istioctl /usr/local/bin/ && \
    rm -rf istio-1.22.1

RUN curl -s https://raw.githubusercontent.com/kurtosis-tech/kardinal-demo-script/master/install.sh -o kardinal_install.sh
# Copy scriptsCOPY scripts/install.sh /usr/local/bin/install.sh
COPY scripts/startup.sh /usr/local/bin/startup.sh

RUN /usr/local/bin/startup.sh