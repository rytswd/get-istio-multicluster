# KinD

## Start local Kubernetes clusters with KinD

```bash
{
    kind create cluster --config ./tools/kind-config/v1.18/config-2-nodes-port-320x1.yaml --name armadillo
    kind create cluster --config ./tools/kind-config/v1.18/config-2-nodes-port-320x2.yaml --name bison
}
```

<details>
<summary>ℹ️ Details</summary>

KinD clusters are created with 2 almost identical configurations. The configuration ensures the Kubernetes version is v1.18 with 2 nodes in place (1 for control plane, 1 for worker).

The difference between the configuration is the open port setup. Because clusters needs to talk to each other, we need them to be externally available. With KinD, external IP does not get assigned by default, and for this demo, we are using NodePort for the entry points, effectively mocking the multi-network setup.

As you can see `istioctl-input.yaml` in each cluster, the NodePort used are:

- Armadillo will set up Istio IngressGateway with 32021 NodePort
- Bison will set up Istio IngressGateway with 32022 NodePort

</details>

## Stop KinD clusters

```bash
{
    kind delete cluster --name armadillo
    kind delete cluster --name bison
}
```
