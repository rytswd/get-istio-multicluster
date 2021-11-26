# KinD

KinD is Kubernetes in Docker. You can find more in https://kind.sigs.k8s.io/.

## Start KinD with 2 clusters

### Start local Kubernetes clusters with KinD

<!-- == export: kind-start-2-clusters / begin == -->

```bash
{
    kind create cluster --config ./tools/kind-config/v1.21/config-2-nodes-port-320x1.yaml --name armadillo
    kind create cluster --config ./tools/kind-config/v1.21/config-2-nodes-port-320x2.yaml --name bison
}
```

<details>
<summary>ℹ️ Details</summary>

KinD clusters are created with 2 almost identical configurations. The configuration ensures the Kubernetes version is v1.21 with 2 nodes in place (1 for control plane, 1 for worker).

The difference between the configuration is the open port setup. Because clusters needs to talk to each other, we need them to be externally available. With KinD, external IP does not get assigned by default, and for this demo, we are using NodePort for the entry points, effectively mocking the multi-network setup.

As you can see `istioctl-input.yaml` in each cluster, the NodePort used are:

- Armadillo will set up Istio IngressGateway with 32021 NodePort
- Bison will set up Istio IngressGateway with 32022 NodePort

Also, because we are using Kubernetes v1.21, we can simply rely on third party JWT for Kubernetes access. With older versions of Kubernetes, you may need to adjust the Istio installation spec with the first party JWT. You can find more about this in the [official documentation about account tokens](https://istio.io/latest/docs/ops/best-practices/security/#configure-third-party-service-account-tokens) and [Istio v1.10 change notes](https://istio.io/latest/news/releases/1.10.x/announcing-1.10/change-notes/).

</details>

<!-- == export: kind-start-2-clusters / end == -->

### Stop KinD clusters

<!-- == export: kind-stop-2-clusters / begin == -->

```bash
{
    kind delete cluster --name armadillo
    kind delete cluster --name bison
}
```

<details>
<summary>ℹ️ Details</summary>

KinD clusters can be deleted with `kind delete cluster` - and you can provide `--name` to specify one.

As the above steps created multiple clusters, you will need to run `kind delete cluster` for each cluster created.

Because all the Istio components are inside KinD cluster, deleting the cluster will remove everything that was generated / configured / deployed.

</details>

<!-- == export: kind-stop-2-clusters / end == -->

## Start KinD with 3 clusters

To be updated

---
