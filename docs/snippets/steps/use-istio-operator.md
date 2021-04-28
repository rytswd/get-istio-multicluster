# Use IstioOperator Controller

You can use IstioOperator Custom Resuorce with `istioctl`, or you can have IstioOperator Controller to handle it for you.

## Install Istio Control Plane components to 2 clusters

<!-- == export: install-control-plane-for-2-clusters / begin == -->

```bash
{
    kubectl create namespace istio-system --context kind-armadillo
    kubectl apply --context kind-armadillo \
        -n istio-system \
        -f ./clusters/armadillo/istio/installation/operator-usage/istio-control-plane.yaml

    kubectl create namespace istio-system --context kind-bison
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

<!-- == export: install-control-plane-for-2-clusters / end == -->

## Install Istio Data Plane (i.e. Gateways) into 2 clusters

<!-- == export: install-data-plane-for-2-clusters / begin == -->

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

<!-- == export: install-data-plane-for-2-clusters / end == -->
