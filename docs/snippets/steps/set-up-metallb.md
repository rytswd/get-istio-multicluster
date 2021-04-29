# MetalLB

MetalLB allows using LoadBalancer in KinD clusters.

## Using KinD and MetalLB

### For Armadillo

<!-- == export: armadillo / begin == -->

```bash
{
    kubectl apply --context kind-armadillo \
        -f ./tools/metallb/installation/metallb-namespace.yaml
    kubectl apply --context kind-armadillo \
        -f ./tools/metallb/installation/metallb-install.yaml

    kubectl create secret --context kind-armadillo \
        generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

    kubectl apply --context kind-armadillo \
        -f ./tools/metallb/usage/metallb-ip-config-101.yaml
}
```

<!-- == export: armadillo / end == -->

### For Bison

<!-- == export: bison / begin == -->

```bash
{
    kubectl apply --context kind-bison \
        -f ./tools/metallb/installation/metallb-namespace.yaml
    kubectl apply --context kind-bison \
        -f ./tools/metallb/installation/metallb-install.yaml

    kubectl create secret --context kind-bison \
        generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

    kubectl apply --context kind-bison \
        -f ./tools/metallb/usage/metallb-ip-config-102.yaml
}
```

<!-- == export: bison / end == -->

### Details

<!-- == export: details / begin == -->

MetalLB allows associating external IP to LoadBalancer Service even in environment such as KinD. The actual installation is simple and straightforward - with the default installation spec, you need to create a namespace `metallb-system` and deploy all the components to that namespace.

```bash
    kubectl apply --context kind-armadillo \
        -f ./tools/metallb/installation/metallb-namespace.yaml
    kubectl apply --context kind-armadillo \
        -f ./tools/metallb/installation/metallb-install.yaml
```

As MetalLB requires a generic secret called `memberlist`, create one with some random data.

```bash
    kubectl create secret --context kind-armadillo \
        generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
```

All the files under `/tools/metallb/installation` are simply copied from the official release. If you prefer using Kustomize and pull in from the official release directly, you can have the following Kustomize spec. This repository aims to prepare all the manifests in the local filesystem, and thus this approach is not taken here.

<details>
<summary>Kustomization spec</summary>

```yaml
# kustomization.yml
namespace: metallb-system

resources:
  - github.com/metallb/metallb//manifests?ref=v0.9.6
```

</details>

Finally, you need to let MetalLB know which IP range it can use to assign to the LoadBalancers.

```bash
    kubectl apply --context kind-armadillo \
        -f ./tools/metallb/usage/metallb-ip-config-101.yaml
```

⚠️ **NOTE** ⚠️:

This step assumes your IP range for Docker network is `172.18.0.0/16`. You can find your Docker network setup with the following command:

```bash
docker network inspect -f '{{.IPAM.Config}}' kind
```

```bash
# ASSUMED OUTPUT
[{172.18.0.0/16  172.18.0.1 map[]} {fc00:f853:ccd:e793::/64  fc00:f853:ccd:e793::1 map[]}]
```

If your IP ranges do not match with the above assumed IP ranges, you will need to adjust the configs to ensure correct IP ranges are provided to MetalLB. If this IP mapping was incorrect, you will find multicluster communication to fail because the clusters cannot talk to each other. In case you corrected the wrong configuration after MetalLB associated incorrect IP to the LoadBalancer, you may find MetalLB not updating the LoadBalancer's external IP. You should be able to delete MetalLB contorller Pod so that it can reassign the IP.

<!-- == export: details / end == -->

## Other References

- MetalLB official installation document: https://metallb.universe.tf/installation/
- KinD document about LoadBalancer usage: https://kind.sigs.k8s.io/docs/user/loadbalancer/
