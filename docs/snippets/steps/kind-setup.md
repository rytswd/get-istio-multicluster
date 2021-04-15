# KinD

KinD is Kubernetes in Docker. You can find more in https://kind.sigs.k8s.io/.

## Start KinD with 2 clusters

### Start local Kubernetes clusters with KinD

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

### Stop KinD clusters

```bash
{
    kind delete cluster --name armadillo
    kind delete cluster --name bison
}
```

<details>
<summary>ℹ️ Details</summary>

KinD clusters can be deleted with `kind delete cluster` - and you can provide `--name` to specify one.

As the above steps creates multiple clusters, this step makes sure to delete all.

Because all the Istio components are inside KinD cluster, deleting the cluster will remove everything that was generated / configured / deployed.

</details>

## Start KinD with 3 clusters

To be updated

---
