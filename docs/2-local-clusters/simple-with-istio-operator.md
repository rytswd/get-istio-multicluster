# KinD-based Setup

## 📝 Setup Details

After following all the steps below, you would get

- 2 clusters (`armadillo`, `bison`)
- 1 mesh
- `armadillo` to send request to `bison`

This setup assumes you are using Istio 1.7.8.

## 📚 Other Setup Steps

<details>
<summary>Click to expand</summary>

<!-- == imptr: setup-steps / begin from: ../snippets/common-info.md#[setup-steps] == -->

#### [Simple KinD based Setup][1]

**Description**: This setup is the easiest to follow, and takes imperative setup steps.

| # of Clusters | Istio Installation Method | Cluster Setup |
| :-----------: | ------------------------- | ------------- |
|       2       | Istio Operator            | [KinD][kind]  |

**Additional Tools involved**: [MetalLB][metallb]

#### [Simple k3d based Setup][2]

**Description**: To be confirmed

| # of Clusters | Istio Installation Method | Cluster Setup |
| :-----------: | ------------------------- | ------------- |
|       2       | TBC                       | [k3d]         |

**Additional Tools involved**: [MetalLB][metallb]

#### [Argo CD based GitOps Multicluster][3]

**Description**: Uses Argo CD to wire up all the necessary tools. This allows simple enough installation steps, while providing breadth of other tools useful to have alongside with Istio.

| # of Clusters | Istio Installation Method | Cluster Setup |
| :-----------: | ------------------------- | ------------- |
|       2       | Manifest Generation       | [KinD][kind]  |

**Additional Tools involved**: [MetalLB][metallb], [Argo CD][argo-cd], [Prometheus][prometheus], [Grafana][grafana], [Kiali][kiali]

[1]: /docs/2-local-clusters/simple-with-istio-operator.md
[2]: /docs/k3d-based/README.md
[3]: /docs/2-local-clusters/argo-cd-with-generated-manifests.md
[kind]: https://kind.sigs.k8s.io/
[k3d]: https://k3d.io/
[metallb]: https://metallb.universe.tf/
[argo-cd]: https://argo-cd.readthedocs.io/en/latest/
[prometheus]: https://prometheus.io/
[grafana]: https://grafana.com/grafana/
[kiali]: https://kiali.io/

<!-- == imptr: setup-steps / end == -->

</details>

## 🐾 Steps

### 0. Clone this repository

<!-- == imptr: full-clone / begin from: ../snippets/steps/use-this-repo.md#[full-clone-command] == -->

```bash
{
    pwd
    # /some/path/at

    git clone https://github.com/rytswd/get-istio-multicluster.git

    cd get-istio-multicluster
    # /some/path/at/get-istio-multicluster
}
```

<!-- == imptr: full-clone / end == -->

For more information about using this repo, you can check out the full documentation in [Using this repo](https://github.com/rytswd/get-istio-multicluster/blob/main/docs/snippets/steps/use-this-repo.md).

---

### 1. Start local Kubernetes clusters with KinD

<!-- == imptr: kind-start / begin from: ../snippets/steps/kind-setup.md#[kind-start-2-clusters] == -->

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

<!-- == imptr: kind-start / end == -->

---

### 2. Prepare CA Certs

**NOTE**: You should complete this step before installing Istio to the cluster.

<!-- == imptr: cert-prep-1 / begin from: ../snippets/steps/prep-cert.md#[prep-certs-with-local-ca] == -->

The first step is to generate the certificates.

```bash
{
    pushd certs > /dev/null
    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts

    popd > /dev/null
}
```

<details>
<summary>ℹ️ Details</summary>

Creating certificates uses Istio's certificate creation setup.

You can find the original documentation [here](https://github.com/istio/istio/tree/master/tools/certs) (or [here for v1.9.2](https://github.com/istio/istio/tree/1.9.2/tools/certs)).

```bash
{
    # Get into certs directory
    pushd certs > /dev/null

    # Create Root CA, which would then be used to sign Intermediate CAs.
    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    # Create Intermediate CA for each cluster. All clusters have their own
    # certs for security reason. These certs are signed by the above Root CA.
    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts

    # Get back to previous directory
    popd > /dev/null
}
```

</details>

<!-- == imptr: cert-prep-1 / end == -->

<!-- == imptr: cert-prep-2 / begin from: ../snippets/steps/prep-cert.md#[prep-kubernetes-secrets] == -->

The second step is to create Kubernetes Secrets holding the generated certificates in the correpsonding clusters.

```bash
{
    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./certs/armadillo/ca-cert.pem \
        --from-file=./certs/armadillo/ca-key.pem \
        --from-file=./certs/armadillo/root-cert.pem \
        --from-file=./certs/armadillo/cert-chain.pem

    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./certs/bison/ca-cert.pem \
        --from-file=./certs/bison/ca-key.pem \
        --from-file=./certs/bison/root-cert.pem \
        --from-file=./certs/bison/cert-chain.pem
}
```

<details>
<summary>ℹ️ Details</summary>

If you do not create the certificate before Istio is installed to the cluster, Istio will fall back to use its own certificate. This will cause an issue when you try to use your custom cert later on. It's best to get the cert ready first - otherwise you will likely need to run through a bunch of restarts of Istio components and others to ensure the correct cert is picked up. This will also likely require inevitable downtime.

As of writing (April 2021), there is some work being done on Istio to provide support for multiple Root certificates.

Ref: https://github.com/istio/istio/issues/31111

Each command used above is associated with some comments to clarify what they do:

```bash
{
    # Create a secret `cacerts`, which is used by Istio.
    # Istio's component `istiod` will use this, and if there is no secret in
    # place before `istiod` starts up, it would fall back to use Istio's
    # default CA which is only menat to be used for testing.
    #
    # The below commands are for Armadillo cluster.
    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./certs/armadillo/ca-cert.pem \
        --from-file=./certs/armadillo/ca-key.pem \
        --from-file=./certs/armadillo/root-cert.pem \
        --from-file=./certs/armadillo/cert-chain.pem
    #
    # The below commands are for Bison cluster.
    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./certs/bison/ca-cert.pem \
        --from-file=./certs/bison/ca-key.pem \
        --from-file=./certs/bison/root-cert.pem \
        --from-file=./certs/bison/cert-chain.pem
}
```

</details>

<!-- == imptr: cert-prep-2 / end == -->

---

### 3. Intsall and Configure MetalLB

#### Armadillo

<!-- == imptr: install-metallb-armadillo / begin from: ../snippets/steps/set-up-metallb.md#[armadillo] == -->

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

<!-- == imptr: install-metallb-armadillo / end == -->

#### Bison

<!-- == imptr: install-metallb-bison / begin from: ../snippets/steps/set-up-metallb.md#[bison] == -->

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

<!-- == imptr: install-metallb-bison / end == -->

<details>
<summary>ℹ️ Details</summary>

<!-- == imptr: install-metallb-details / begin from: ../snippets/steps/set-up-metallb.md#[details] == -->

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

<!-- == imptr: install-metallb-details / end == -->

</details>

---

### 4. Install IstioOperator Controller into Clusters

<details>
<summary>With istioctl</summary>

<!-- == imptr: install-istio-operator-with-istioctl / begin from: ../snippets/steps/install-istio-operator.md#[istio-operator-with-istioctl] == -->

> 📝 **NOTE**:  
> This will install Istio version based on `istioctl` version you have on your machine. You will need to manage your `istioctl` version separately, or you could take manifest generation approach instead, which is based on declarative and static definitions.

```bash
{
    istioctl --context kind-armadillo \
        operator init \
        -f ./clusters/armadillo/istio/installation/operator-install/istio-operator-install.yaml

    istioctl --context kind-bison \
        operator init \
        -f ./clusters/bison/istio/installation/operator-install/istio-operator-install.yaml
}
```

<!-- == imptr: install-istio-operator-with-istioctl / end == -->

</details>

<details>
<summary>With manifest generation</summary>

<!-- == imptr: install-istio-operator-with-manifest / begin from: ../snippets/steps/install-istio-operator.md#[istio-operator-with-manifest-generation] == -->

```bash
{
    kubectl apply --context kind-armadillo \
        -f ./clusters/armadillo/istio/installation/operator-install/istio-operator-install.yaml

    kubectl apply --context kind-bison \
        -f ./clusters/bison/istio/installation/operator-install/istio-operator-install.yaml
}
```

When you see error messages such as:

```console
Error from server (NotFound): error when creating "./clusters/armadillo/istio/installation/operator-install/istio-operator-install.yaml": namespaces "istio-operator" not found
```

You can simply run the above command one more time. <!--TODO: Add more details-->

<!-- == imptr: install-istio-operator-with-manifest / end == -->

</details>

<details>
<summary>ℹ️ Details</summary>

<!-- == imptr: install-istio-operator-details / begin from: ../snippets/steps/install-istio-operator.md#[istio-operator-details] == -->

This prepares for Istio installation by installing IstioOperator Controller. It allows defining IsitoOperator Custom Resource in declarative manner, and IstioOperator Controller to handle the installation.

You can use `istioctl operator init` to install, or get the IstioOperator Controller installation spec with `istioctl operator dump`. In multicluster scenario, it is safer to have all clusters with the same Istio version, and thus you could technically use the same spec.

As this repository aims to be as declarative as possible, the installation specs are saved using `istioctl operator dump`, and saved under each cluster spec. You can use `get-istio-multicluster/tools/internal/update-istio-operator-install.sh` script to update all the IstioOperator Controller installation spec in one go.

<!-- == imptr: install-istio-operator-details / end == -->

</details>

---

### 5. Install Istio Control Plane into Clusters

<!-- == imptr: use-istio-operator-control-plane / begin from: ../snippets/steps/use-istio-operator.md#[install-control-plane-for-2-clusters] == -->

```bash
{
    kubectl apply --context kind-armadillo \
        -n istio-system \
        -f ./clusters/armadillo/istio/installation/operator-usage/istio-control-plane.yaml

    kubectl apply --context kind-bison \
        -n istio-system \
        -f ./clusters/bison/istio/installation/operator-usage/istio-control-plane.yaml
}
```

<details>
<summary>ℹ️ Details</summary>

This step simply deploys IstioOperator CustomResource to the cluster, and rely on IstioOperator Controller to deploy Istio into the cluster.

As to the configuration files, the above commands use basically identical cluster setup input for 2 clusters.

This installation uses the IstioOperator manifest with `minimal` profile, meaning this would be used for installing Istio "Control Plane" components. They are the core copmonents of Istio to provide its rich traffic management, security, and observability features, and mainly driven by an image of `istiod` (and a few more things around it). Some more differences would be seen for "Data Plane" components, and that would be dealt in the next step.

</details>

<!-- == imptr: use-istio-operator-control-plane / end == -->

---

### 6. Install Istio Data Plane (i.e. Gateways) into Clusters

<!-- == imptr: use-istio-operator-data-plane / begin from: ../snippets/steps/use-istio-operator.md#[install-data-plane-for-2-clusters] == -->

```bash
{
    kubectl apply --context kind-armadillo \
        -n istio-system \
        -f clusters/armadillo/istio/installation/operator-usage/istio-external-gateways.yaml \
        -f clusters/armadillo/istio/installation/operator-usage/istio-multicluster-gateways.yaml

    kubectl apply --context kind-bison \
        -n istio-system \
        -f clusters/bison/istio/installation/operator-usage/istio-external-gateways.yaml \
        -f clusters/bison/istio/installation/operator-usage/istio-multicluster-gateways.yaml
}
```

<details>
<summary>ℹ️ Details</summary>

This step installs "Data Plane" components into the clusters, which are mainly Istio Ingress and Egress Gateways. You can think of Data Plane components as actually running service (in this case IngressGateway which is `docker.io/istio/proxyv2` image), and they will be controlled by Control Plane components (`istiod`).

The main difference in the configuration files used above is the name used by various components (Ingress and Egress Gateways have `armadillo-` or `bison-` prefix, and so on). Also, as the previous step created the KinD cluster with different NodePort for Istio IngressGateway, you can see the corresponding port being used in `istio-multicluster-gateways.yaml`.

</details>

<!-- == imptr: use-istio-operator-data-plane / end == -->

---

### 7. Install Debug Processes

<!-- == imptr: deploy-debug-services / begin from: ../snippets/steps/deploy-debug-services.md#[for-2-clusters] == -->

```bash
{
    kubectl create namespace --context kind-armadillo armadillo-offerings
    kubectl label namespace --context kind-armadillo armadillo-offerings istio-injection=enabled
    kubectl apply --context kind-armadillo \
        -n armadillo-offerings \
        -f clusters/armadillo/other/httpbin.yaml \
        -f clusters/armadillo/other/color-svc-account.yaml \
        -f clusters/armadillo/other/color-svc-only-blue.yaml \
        -f clusters/armadillo/other/toolkit-alpine.yaml

    kubectl create namespace --context kind-bison bison-offerings
    kubectl label namespace --context kind-bison bison-offerings istio-injection=enabled
    kubectl apply --context kind-bison \
        -n bison-offerings \
        -f clusters/bison/other/httpbin.yaml \
        -f clusters/bison/other/color-svc-account.yaml \
        -f clusters/bison/other/color-svc-only-red.yaml \
        -f clusters/bison/other/toolkit-alpine.yaml
}
```

<details>
<summary>ℹ️ Details</summary>

There are 3 actions happening, and for 2 clusters (Armadillo and Bison).

Firstly, `kubectl create namespace` is called to create namespaces where the debug processes are being installed.

Secondly, `kubectl label namespace default istio-injection=enabled` marks that namespace (in this case `default` namespace) as Istio Sidecar enabled. This means any Pod that gets created in this namespace will go through Istio's MutatingWebhook, and Istio's Sidecar component (`istio-proxy`) will be embedded into the Pod. Without this setup, you will need to add Sidecar separately by running `istioctl` commands, which may be ok for testing, but certainly not scalable.

Third action is to install the testing tools.

- `httpbin` is a copy of httpbin.org, which can handle incoming HTTP request and return arbitrary output based on the input path.
- [`color-svc`](color-svc) is a simple web server which handles incoming HTTP request, and returns some random color. The configurations used in each cluster are slightly different, and produces different set of colors.
- [`toolkit-alpine`](toolkit-alpine) is a lightweight container which has a few tools useful for testing, such as `curl`, `dig`, etc.

For both `color-svc` and `toolkit-alpine`, [`tools`](/tools) directory has the copy of the predefined YAML files. You can find more about how they are created in their repos.

- [github.com/rytswd/color-svc](color-svc)
- [github.com/rytswd/docker-toolkit-images](toolkit-alpine)

[color-svc]: https://github.com/rytswd/color-svc
[toolkit-alpine]: https://github.com/rytswd/docker-toolkit-images

</details>

<!-- == imptr: deploy-debug-services / end == -->

---

### 8. Apply Istio Custom Resources

Each cluster has different resources. Check out the documentation one by one.

### For Armadillo

<details>
<summary>8.1. Add <code>istiocoredns</code> as a part of CoreDNS ConfigMap</summary>

<!-- == imptr: manual-coredns / begin from: ../snippets/steps/handle-istio-resources-manually.md#[armadillo-coredns] == -->

Get IP address of `istiocoredns` Service,

```bash
{
    export ARMADILLO_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc \
        --context kind-armadillo \
        -n istio-system \
        istiocoredns \
        -o jsonpath={.spec.clusterIP})
    echo "$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP"
}
```

```sh
# OUTPUT
10.xx.xx.xx
```

And then apply CoreDNS configuration which includes the `istiocoredns` IP.

```bash
{
    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP/" \
        ./clusters/armadillo/istio/installation/additional-setup/coredns-configmap.yaml
    kubectl apply --context kind-armadillo \
        -f ./clusters/armadillo/istio/installation/additional-setup/coredns-configmap.yaml
}
```

```sh
# OUTPUT
Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
configmap/coredns configured
```

The above example is only to update CoreDNS for Armadillo cluster, meaning traffic initiated from Armadillo cluster.

<details>
<summary>ℹ️ Details</summary>

Istio's `istiocoredns` handles DNS lookup, and thus, you need to let Kubernetes know that `istiocoredns` gets the DNS request. Get the K8s Service cluster IP in `ARMADILLO_ISTIOCOREDNS_CLUSTER_IP` env variable, so that you can use that in `coredns-configmap.yaml` as the endpoint.

This will then be applied to `kube-system/coredns` ConfigMap. As KinD comes with CoreDNS as the default DNS and its own ConfigMap, you will see a warning about the original ConfigMap being overridden with the custom one. This is fine for testing, but you may want to carefully examine the DNS setup as that could have significant impact.

The `sed` command may look confusing, but the change is very minimal and straighforward. If you cloned this repo at the step 0, you can easily see from git diff.

```diff
diff --git a/clusters/armadillo/istio/installation/additional-setup/coredns-configmap.yaml b/clusters/armadillo/istio/installation/additional-setup/coredns-configmap.yaml
index 9ffb5e8..d55a977 100644
--- a/clusters/armadillo/istio/installation/additional-setup/coredns-configmap.yaml
+++ b/clusters/armadillo/istio/installation/additional-setup/coredns-configmap.yaml
@@ -26,5 +26,5 @@ data:
     global:53 {
         errors
         cache 30
-        forward . REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP:53
+        forward . 10.96.238.217:53
     }
```

</details>

<!-- == imptr: manual-coredns / end == -->

---

</details>

<details>
<summary>8.2. Add traffic routing for Armadillo local, and prepare for multicluster outbound</summary>

<!-- == imptr: manual-routing-armadillo / begin from: ../snippets/steps/handle-istio-resources-manually.md#[armadillo-local] == -->

For local routing

```bash
{
    kubectl apply --context kind-armadillo \
        -f ./clusters/armadillo/istio/traffic-management/local/color-svc.yaml \
        -f ./clusters/armadillo/istio/traffic-management/local/httpbin.yaml
}
```

```console
destinationrule.networking.istio.io/armadillo-color-svc created
virtualservice.networking.istio.io/armadillo-color-svc-routing created
virtualservice.networking.istio.io/armadillo-httpbin-chaos-routing created
```

For multicluster outbound routing

```bash
{
    kubectl apply --context kind-armadillo \
        -f ./clusters/armadillo/istio/traffic-management/multicluster/multicluster-setup.yaml
}
```

```console
gateway.networking.istio.io/armadillo-multicluster-ingressgateway created
envoyfilter.networking.istio.io/armadillo-multicluster-ingressgateway created
destinationrule.networking.istio.io/multicluster-traffic-from-armadillo created
```

<details>
<summary>ℹ️ Details</summary>

The first command will create local routing setup within Armadillo for testing traffic management in a single cluster.

The second command will create multicluster setup for Armadillo. This includes `Gateway` and `EnvoyFilter` Custom Resources which are responsible for inbound traffic, and `DestinationRule` Custom Resource for outbound traffic. Strictly speaking, you would only need the outbound traffic setup for Armadillo cluster to talk to remote clusters, but setting up with the above file allows other clusters to talk to Armadillo as well.

</details>

<!-- == imptr: manual-routing-armadillo / end == -->

---

</details>

<details>
<summary>8.3. Add ServiceEntry for Bison connection</summary>

<!-- == imptr: manual-multicluster-routing-armadillo / begin from: ../snippets/steps/handle-istio-resources-manually.md#[armadillo-multicluster-bison] == -->

```bash
kubectl apply --context kind-armadillo \
    -f ./clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml \
    -f ./clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
```

```console
serviceentry.networking.istio.io/bison-color-svc created
virtualservice.networking.istio.io/bison-color-svc-routing created
serviceentry.networking.istio.io/bison-httpbin created
virtualservice.networking.istio.io/bison-httpbin-routing created
```

<details>
<summary>ℹ️ Details</summary>

To be updated

</details>

<!-- == imptr: manual-multicluster-routing-armadillo / end == -->

---

</details>

### For Bison

<details>
<summary>8.4. Add traffic routing for Bison local, and prepare for multicluster outbound</summary>

<!-- == imptr: manual-routing-bison / begin from: ../snippets/steps/handle-istio-resources-manually.md#[bison-local] == -->

For local routing

```bash
{
    kubectl apply --context kind-bison \
        -f ./clusters/bison/istio/traffic-management/local/color-svc.yaml \
        -f ./clusters/bison/istio/traffic-management/local/httpbin.yaml
}
```

```sh
# OUTPUT
destinationrule.networking.istio.io/bison-color-svc created
virtualservice.networking.istio.io/bison-color-svc-routing created
virtualservice.networking.istio.io/bison-httpbin-routing created
```

For multicluster outbound routing

```bash
{
    kubectl apply --context kind-bison \
        -f ./clusters/bison/istio/traffic-management/multicluster/multicluster-setup.yaml
}
```

```sh
# OUTPUT
gateway.networking.istio.io/bison-multicluster-ingressgateway created
envoyfilter.networking.istio.io/bison-multicluster-ingressgateway created
destinationrule.networking.istio.io/multicluster-traffic-from-bison created
```

<details>
<summary>ℹ️ Details</summary>

This is the same step as done in Armadillo cluster setup, but for Bison.

</details>

<!-- == imptr: manual-routing-bison / end == -->

</details>

---

### 9. Verify

<!-- == imptr: verify-with-httpbin / begin from: ../snippets/steps/verify-with-httpbin.md#[curl-httpbin-2-clusters] == -->

Simple curl to verify connection

```bash
kubectl exec \
    --context kind-armadillo \
    -n armadillo-offerings \
    -it \
    $(kubectl get pod \
        --context kind-armadillo \
        -n armadillo-offerings \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- curl -vvv httpbin.bison-offerings.global:8000/status/418
```

Interactive shell from Armadillo cluster

```bash
kubectl exec \
    --context kind-armadillo \
    -n armadillo-offerings \
    -it \
    $(kubectl get pod \
        --context kind-armadillo \
        -n armadillo-offerings \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- bash
```

For logs

```bash
kubectl logs \
    --context kind-armadillo \
    -n armadillo-offerings \
    $(kubectl get pod \
        --context kind-armadillo \
        -n armadillo-offerings \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c istio-proxy \
    | less
```

<details>
<summary>ℹ️ Details</summary>

`kubectl exec -it` is used to execute some command from the main container deployed from 4. Install Debug Processes.

The verification uses `curl` to connect from Armadillo's "toolkit" to Bison's "httpbin". The address here `httpbin.default.bison.global` is intentionally different from the Istio's official guidance of `httpbin.default.global`, as this would be important if you need to connect more than 2 clusters to form the mesh. This address of `httpbin.default.bison.global` can be pretty much anything you want, as long as you have the proper conversion logic defined in the target cluster - in this case Bison.

_TODO: More to be added_

</details>

<!-- == imptr: verify-with-httpbin / end == -->

---

## 🧹 Cleanup

For stopping clusters

<!-- == imptr: kind-stop / begin from: ../snippets/steps/kind-setup.md#[kind-stop-2-clusters] == -->

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

<!-- == imptr: kind-stop / end == -->

<!-- == imptr: cert-removal / begin from: ../snippets/steps/prep-cert.md#[delete-certs] == -->

Provided that you are using some clone of this repo, you can run the following to remove certs.

```bash
{
    rm -rf certs
    git checkout certs --force
}
```

<details>
<summary>ℹ️ Details</summary>

Remove the entire `certs` directory, and `git checkout certs --force` to remove all the changes.

If you are simply pulling the files without Git, you can run:

```bash
{
    rm -rf certs
    mkdir certs
}
```

</details>

<!-- == imptr: cert-removal / end == -->

If you have updated the local files with some of commands above, you may want to clean up those changes as well.

```bash
git reset --hard
```
