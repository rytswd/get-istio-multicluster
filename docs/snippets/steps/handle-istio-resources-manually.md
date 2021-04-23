# Handling Istio Custom Resources Manually

## Patch CoreDNS usage

For intercluster DNS resolution, you need to apply the following to all clusters.

<!-- == export: armadillo-coredns / begin == -->

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

The above example is only to update CoreDNS for Armadillo cluster. If you want to have Bison to Armadillo traffic the same way, you'd need to run the same command for Bison cluster as well (with `--context kind-bison`).

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

<!-- == export: armadillo-coredns / end == -->

## Armadillo cluster

### Routing Setup

<!-- == export: armadillo-local / begin == -->

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

<!-- == export: armadillo-local / end == -->

### Multicluster Routing Setup

<!-- == export: armadillo-multicluster-bison / begin == -->

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
        ./clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        ./clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
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
            ./clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml
        if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32022/" \
                ./clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml
        fi
        sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
            ./clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
        if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32022/" \
                ./clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
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
    -f ./clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml \
    -f ./clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
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

```diff
diff --git a/clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml b/clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml
index 8d5eabc..0d455c4 100644
--- a/clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml
+++ b/clusters/armadillo/istio/traffic-management/multicluster/bison-color-svc.yaml
@@ -18,11 +18,11 @@ spec:
   addresses:
     - 240.0.0.2
   endpoints:
-    - address: REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS
+    - address: 172.18.0.1
       network: external
       ports:
-        http-bison: 15443 # Istio Ingress Gateway port
-    - address: REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP
+        http-bison: 32022
+    - address: 10.96.52.18
       ports:
         http-bison: 15443
 ---
```

```diff
diff --git a/clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml b/clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
index 0d73f22..34a3762 100644
--- a/clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
+++ b/clusters/armadillo/istio/traffic-management/multicluster/bison-httpbin.yaml
@@ -18,11 +18,11 @@ spec:
   addresses:
     - 240.0.0.1
   endpoints:
-    - address: REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS
+    - address: 172.18.0.1
       network: external
       ports:
-        http-bison: 15443 # Istio Ingress Gateway port
-    - address: REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP
+        http-bison: 32022
+    - address: 10.96.52.18
       ports:
         http-bison: 15443
 ---
```

</details>

<!-- == export: armadillo-multicluster-bison / end == -->

## Bison cluster

### Routing Setup

<!-- == export: bison-local / begin == -->

For local routing

```bash
{
    kubectl apply --context kind-bison \
        -f ./clusters/bison/istio/traffic-management/local/color-svc.yaml \
        -f ./clusters/bison/istio/traffic-management/local/httpbin.yaml
}
```

For multicluster outbound routing

```bash
{
    kubectl apply --context kind-bison \
        -f ./clusters/bison/istio/traffic-management/multicluster/multicluster-setup.yaml
}
```

<details>
<summary>ℹ️ Details</summary>

To be updated

</details>

<!-- == export: bison-local / end == -->

## Istio v1.6

If you are using Istio v1.6, you will get an error from the above. You need to run the following command:

```bash
kubectl apply --context kind-bison \
    -f ./clusters/bison/istio/traffic-management/archive-for-istio-1.6/multicluster-setup-1.6.yaml
```
