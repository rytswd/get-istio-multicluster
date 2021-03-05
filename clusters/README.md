# Cluster Definitions

This directory contains all the configuration files used for setting up each clusters.

Each cluster can be set up individually, and also multicluster setup is done in various approaches.

# About Each Cluster

## 📚 Common Stack

Each cluster has its own definition for every tech stack. They can refer to some common directory if they want to share the same exact version, but this is done on purpose so that each cluster can manage their own version.

On top of Istio, each cluster can be configured with the following

| App        | Version | Type          | Installation Pattern       |
| ---------- | :-----: | ------------- | -------------------------- |
| Argo CD    | v1.8.2  | GitOps        | Kubernetes YAML            |
| Prometheus |   TBC   | Observability | Operator, version v0.45.0  |
| Grafana    |   TBC   | Observability | Helm Chart, version v6.3.0 |
| Kiali      |   TBC   | Observability | Operator, version v1.29.0  |
| Jaeger     | v1.21.3 | Observability | Operator, version v1.21.3  |

### How to update all

Each tool can be updated separately in each cluster directory.

Otherwise the version upgrade can take place for all the clusters via scripts under [`/tools/internal/`](https://github.com/rytswd/get-istio-multicluster/tree/main/tools/internal).

## Armadillo

- Dedicated Control Plane
- Connects to Bison

## Bison

- Dedicated Control Plane
- Connects to Armadillo
