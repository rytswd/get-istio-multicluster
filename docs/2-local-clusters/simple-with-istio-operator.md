# KinD-based Setup

## 📝 Setup Details

After following all the steps below, you would get

- 2 clusters (`armadillo`, `bison`)
- 1 mesh
- `armadillo` to send request to `bison`

This setup assumes you are using Istio 1.7.5.

## 📚 Other Setup Steps

<!-- == imptr: other-setup-steps / begin from: ../snippets/links-to-other-steps.md#2~12 == -->
<!-- == imptr: other-setup-steps / end == -->

## 🐾 Steps

### 0. Clone this repository

<!-- == imptr: full-clone / begin from: ../snippets/steps/using-this-repo.md#24~36 == -->
<!-- == imptr: full-clone / end == -->

For more information about using this repo, you can chekc out the full documentation in [Using this repo](https://github.com/rytswd/get-istio-multicluster/blob/main/docs/snippets/steps/using-this-repo.md).

---

### 1. Start local Kubernetes clusters with KinD

<!-- == imptr: kind-start / begin from: ../snippets/steps/kind-setup.md#8~29 == -->
<!-- == imptr: kind-start / end == -->

---

### 2. Prepare CA Certs

**NOTE**: You should complete this step before installing Istio to the cluster.

<!-- == imptr: cert-prep-1 / begin from: ../snippets/steps/cert-prep.md#4~45 == -->
<!-- == imptr: cert-prep-1 / end == -->

<!-- == imptr: cert-prep-2 / begin from: ../snippets/steps/cert-prep.md#47~109 == -->
<!-- == imptr: cert-prep-2 / end == -->

---

### 3. Install IstioOperator Controller into Clusters

<details>
<summary>With `istioctl`</summary>

<!-- == imptr: install-istio-operator-with-istioctl / begin from: ../snippets/steps/install-istio-operator.md#4~16 == -->
<!-- == imptr: install-istio-operator-with-istioctl / end == -->

</details>

<details>
<summary>With manifest generation</summary>

<!-- == imptr: install-istio-operator-with-manifest / begin from: ../snippets/steps/install-istio-operator.md#18~36 == -->
<!-- == imptr: install-istio-operator-with-manifest / end == -->

</details>

<details>
<summary>ℹ️ Details</summary>

<!-- == imptr: install-istio-operator-details / begin from: ../snippets/steps/install-istio-operator.md#38~44 == -->
<!-- == imptr: install-istio-operator-details / end == -->

</details>

---

### 4. Install Istio Control Plane into Clusters

<!-- == imptr: use-istio-operator-control-plane / begin from: ../snippets/steps/use-istio-operator.md#6~29 == -->
<!-- == imptr: use-istio-operator-control-plane / end == -->

---

### 5. Install Istio Data Plane (i.e. Gateways) into Clusters

<!-- == imptr: use-istio-operator-data-plane / begin from: ../snippets/steps/use-istio-operator.md#31~54 == -->
<!-- == imptr: use-istio-operator-data-plane / end == -->

---

### 6. Install Debug Processes

<!-- == imptr: deploy-debug-services / begin from: ../snippets/steps/deploy-debug-services.md#2~49 == -->
<!-- == imptr: deploy-debug-services / end == -->

---

### 7. Apply Istio Custom Resources

Each cluster has different resources. Check out the documentation one by one.

<details>
<summary>For Armadillo</summary>

#### 7.1. Add `istiocoredns` as a part of CoreDNS ConfigMap

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

```bash
{
    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP/" \
        clusters/armadillo/istio/installation/additional-setup/coredns-configmap.yaml
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/istio/installation/additional-setup/coredns-configmap.yaml
}
```

```sh
# OUTPUT
Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
configmap/coredns configured
```

<details>
<summary>ℹ️ Details</summary>

Istio's `istiocoredns` handles DNS lookup, and thus, you need to let Kubernetes know that `istiocoredns` gets the DNS request. Get the K8s Service cluster IP in `ARMADILLO_ISTIOCOREDNS_CLUSTER_IP` env variable, so that you can use that in `coredns-configmap.yaml` as the endpoint.

This will then be applied to `kube-system/coredns` ConfigMap. As KinD comes with CoreDNS as the default DNS and its own ConfigMap, you will see a warning about the original ConfigMap being overridden with the custom one. This is fine for testing, but you may want to carefully examine the DNS setup as that could have significant impact.

</details>

---

#### 7.2. Add traffic routing for Armadillo local, and prepare for multicluster outbound

For local routing

```bash
{
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/istio/traffic-management/local/color-svc.yaml \
        -f clusters/armadillo/istio/traffic-management/local/httpbin.yaml
}
```

```sh
destinationrule.networking.istio.io/armadillo-color-svc created
virtualservice.networking.istio.io/armadillo-color-svc-routing created
virtualservice.networking.istio.io/armadillo-httpbin-chaos-routing created
```

For multicluster outbound routing

```bash
{
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/istio/traffic-management/multicluster/multicluster-setup.yaml
}
```

```sh
To be updated
```

<details>
<summary>ℹ️ Details</summary>

The first command will create local routing within Armadillo to test out the traffic management in a single cluster.

The second command will create multicluster setup for Armadillo. This includes `Gateway` and `EnvoyFilter` Custom Resources which are responsible for inbound traffic, and `DestinationRule` Custom Resource for outbound traffic. Strictly speaking, you would only need the outbound traffic setup for this particular test, but setting up with the above file allows Bison to talk to Armadillo as well.

</details>

---

#### 7.3. Add ServiceEntry for Bison connection

Before completing this, make sure the cluster Bison is also started, and has completed Istio installation.

```bash
{
    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    echo "$ARMADILLO_EGRESS_GATEWAY_ADDRESS"
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
}
```

```sh
# OUTPUT
10.xx.xx.xx
```

```bash
{
    export BISON_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-bison \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    echo "$BISON_INGRESS_GATEWAY_ADDRESS"
    {
        sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
            clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml
        if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32022/" \
                clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml
        fi
        sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
            clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
        if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32022/" \
                clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
        fi
    }
}
```

```sh
# OUTPUT
172.18.0.1
```

```bash
kubectl apply --context kind-armadillo \
    -f clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml \
    -f clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
```

```sh
# OUTPUT
serviceentry.networking.istio.io/bison-color-svc created
virtualservice.networking.istio.io/bison-color-svc-routing created
serviceentry.networking.istio.io/bison-httpbin created
virtualservice.networking.istio.io/bison-httpbin-routing created
```

<details>
<summary>ℹ️ Details</summary>

**WARNING**: The current setup does NOT go through EgressGateway, and simply skips it. This needs further investigation.

There are 2 places that are being updated in a single file `clusters/armadillo/istio/traffic-management/multicluster/bison-connections.yaml`. The first one is for Armadillo's EgressGateway, and the second is for Bison's IngressGateway. This means the traffic follows the below pattern.

```
[ Armadillo Cluster]                                  Cluster Border                                         [ Bison Cluster]
                                                             |
App Container A ==> Istio Sidecar Proxy ==> Egress Gateway ==|==> Ingress Gateway ==> Istio Sidecar Proxy ==> App Container B
                                                             |
```

This means that, when you need App Container A to talk to App Container B on the other cluster, you need to provide 2 endpoints.

In order for 2 KinD clusters to talk to each other, the extra `sed` takes place to fallback to use `172.18.0.1` as endpoint address (which is a mapping outside of cluster), and because Bison's Ingress Gateway is set up with NodePort of `32022`, we replace the default port of `15443` with `32022`.

The command may look confusing, but the update is simple. If you cloned this repo at the step 0, you can easily see from git diff.

</details>

---

</details>

<details>
<summary>For Bison</summary>

```bash
{
    kubectl apply --context kind-bison \
        -f clusters/bison/istio/traffic-management/local/color-svc.yaml \
        -f clusters/bison/istio/traffic-management/local/httpbin.yaml
    kubectl apply --context kind-bison \
        -f clusters/bison/istio/traffic-management/multicluster/multicluster-setup.yaml
}
```

If you are using Istio v1.6, you will get an error from the above. You need to run the following command:

```bash
kubectl apply --context kind-bison \
    -f clusters/bison/istio/traffic-management/archive-for-istio-1.6/multicluster-setup-1.6.yaml
```

<details>
<summary>ℹ️ Details</summary>

To be updated

</details>

</details>

---

### 8. Verify

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

---

## 🧹 Cleanup

For stopping clusters

<!-- == imptr: kind-stop / begin from: ../snippets/steps/kind-setup.md#31~49 == -->
<!-- == imptr: kind-stop / end == -->

<!-- == imptr: cert-removal / begin from: ../snippets/steps/cert-prep.md#111~136 == -->
<!-- == imptr: cert-removal / end == -->
