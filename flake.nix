{
  description = "Go development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    kardinal.url = "github:kurtosis-tech/kardinal/4be70324e7b2";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    unstable,
    kardinal,
    ...
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              kardinal = kardinal.outputs.packages.${system};
            })
          ];
        };
      in {
        devShells.default = let
          start-local-cluster = pkgs.writeShellApplication {
            name = "start-local-cluster";
            runtimeInputs = with pkgs; [minikube istioctl kubectl];
            text = ''
              kubectl config set-context minikube
              minikube start --driver=docker
              minikube addons enable ingress
              minikube addons enable metrics-server

              istioctl install --set profile=minimal --set meshConfig.accessLogFile=/dev/stdout -y

              kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

              kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/prometheus.yaml
              kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/grafana.yaml
              kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/jaeger.yaml
              kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/kiali.yaml
              kubectl rollout status deployment/kiali -n istio-system
            '';
          };

          kardinal-cli = pkgs.stdenv.mkDerivation {
            name = "kardinal";
            dontUnpack = true;
            buildInputs = [pkgs.kardinal.kardinal-cli];
            installPhase = ''
              mkdir -p $out/bin
              ln -s ${pkgs.kardinal.kardinal-cli}/bin/kardinal.cli $out/bin/kardinal
            '';
          };
        in
          pkgs.mkShell {
            buildInputs = with pkgs; [
              go
              gopls
              go-tools
              golangci-lint
              reflex

              # local demo tools
              kardinal-cli
              minikube
              kubectl
              istioctl
              telepresence2

              # Scripts
              start-local-cluster
            ];

            shellHook = ''
              source <(kardinal completion bash)
              echo "Go development environment loaded"
              go version
            '';
          };
      }
    );
}
