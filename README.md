# Simple Istio Multicluster

Istio Multicluster is by no means simple, as there are so many features Istio provides.This repository tries to showcase some of Istio's capability with the following in mind:

- Simple configurations
- Simple processes / containers
- Simple steps to reproduce

But as this repository aims to provide practical use cases, you will also find:

- Involved cluster / mesh setup
- Detailed description on each step

#### 📍 NOTE 📍

> This repository does not aim to be exhaustive by any means. The examples here set out the foundation for multicluster communication, and use some features such as fault injections. You are expected to be somewhat familiar with Istio's features.  
> Also, it is worth noting that most of the examples focus on traffic management features as of Oct 2020. You can find more in the [official documentation of Istio concepts](https://istio.io/latest/docs/concepts/).

## 🌅 Contents

| Setup        | Istio Version | Description                                                            |
| ------------ | :-----------: | ---------------------------------------------------------------------- |
| [KinD-based] | 1.6<br />1.7  | Set up multiple [KinD](https://kind.sigs.k8s.io/) clusters, each having its own Istio Control Plane.<br />This is suitable for getting started and understanding multicluster setup as well as testing some features with it.<br /><br /> This setup can be run completely locally, though depending on your machine spec, you may need to adjust the setup accordingly for stable environment. |
| k3d-based    |      WIP      | Set up multicluster with [k3s](https://k3s.io/) clusters using [k3d](https://k3d.io/).<br /><br />This setup is about the same as KinD-based, but is lighter thanks to k3s.|
| Argo CD      |      WIP      | Set up GitOps cluster setup using Argo CD. This setup also uses KinD clusters, but at the same time you would need a remote Git repo to connect to.  |
| Public Cloud |      WIP      | WIP                                                                    |

[kind-based]: https://github.com/rytswd/simple-istio-multicluster/tree/main/docs/kind-based/README.md

### ⚙️ Prerequisites

For most of the setup, you will need the following tools installed:

- Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [KinD](https://kind.sigs.k8s.io/)
- [istioctl](https://istio.io/latest/docs/setup/install/istioctl/)

### 🌍 Clusters

The clusters used in this repository are given easily identifiable names. They are not meant to convey any meaning.

For some cluster, there are some peculiarities over the others.

- `armadillo`: cluster with shared Istio Control Plane (with `cougar`)
- `bison`: cluster with dedicated Istio Control Plane
- `cougar` ⚠️ WIP ⚠️: clustter with shared Istio Control Plane (with `armadillo`)
- `dolphin`: cluster with dedicated Istio Control Plane
- `zebra` ⚠️ WIP ⚠️: cluster without Istio, as external cluster
