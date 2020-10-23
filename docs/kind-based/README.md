# KinD-bsed Setup

## 📝 Setup Details

After following all the steps below, you would get

- 3 clusters (`armadillo`, `bison`, `dolphin`)
- 1 mesh
- `armadillo` to send request to `bison` and `dolphin`

### Other Setup Steps

| Name    | Description                                           |
| ------- | ----------------------------------------------------- |
| Default | This page                                             |
| [Light] | Creates only 2 clusters - quickest and smallest       |
| [v1.6]  | The same setup as default, but uses Istio version 1.6 |

[light]: https://github.com/rytswd/simple-istio-multicluster/tree/master/docs/kind-based/light.md
[v1.6]: https://github.com/rytswd/simple-istio-multicluster/tree/master/docs/kind-based/v1.6.md

## 🐾 Steps

### 0. Clone this repository

```bash
$ pwd
/some/path/at

$ git clone https://github.com/rytswd/simple-istio-multicluster.git
```

From here on, all the steps are assumed to be run from `/some/path/at/simple-istio-multicluster`.

### 1. Start local Kubernetes clusters with KinD

```bash
{
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32001.yaml --name armadillo
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32002.yaml --name bison
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32004.yaml --name dolphin
}
```

<details>
<summary>Details</summary>

KinD clusters are created with 3 almost identical configurations. The configuration ensures the Kubernetes version is v1.17 with 2 nodes in place (1 for control plane, 1 for worker).

The difference between the configuration is the open port setup. Because clusters needs to talk to each other, we need them to be externally available. With KinD, external IP does not get assigned by default, and for this demo, we are using NodePort for the entry points, effectively mocking the multi-network setup.

As you can see `istioctl-input.yaml` in each cluster, the NodePort used are:

- Armadillo will set up Istio IngressGateway with 32001 NodePort
- Bison will set up Istio IngressGateway with 32002 NodePort
- Dolphin will set up Istio IngressGateway with 32004 NodePort

</details>

---

### 2. Prepare CA Certs

The steps are detailed at [Certificate Preparation steps](https://github.com/rytswd/simple-istio-multicluster/tree/master/docs/cert-prep/README.md).

You need to complete this step before installing Istio to the cluster. Essentially, you need to run the following:

```bash
{
    pushd certs > /dev/null
    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk dolphin-cacerts

    popd > /dev/null

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

    kubectl create namespace --context kind-dolphin istio-system
    kubectl create secret --context kind-dolphin \
        generic cacerts -n istio-system \
        --from-file=./certs/dolphin/ca-cert.pem \
        --from-file=./certs/dolphin/ca-key.pem \
        --from-file=./certs/dolphin/root-cert.pem \
        --from-file=./certs/dolphin/cert-chain.pem
}
```

<details>
<summary>Details</summary>

If you do not create the certificate before Istio is installed to the cluster, Istio will fall back to use its own certificate. This will cause an issue when you try to use your custom cert later on. It's best to get the cert ready first - otherwise you will likely need to run through a bunch of restarts of Istio components to ensure the correct cert is picked up.

Each command is associated with some comments to clarify what they do:

```bash
{
    # Get into certs directory
    pushd certs > /dev/null

    # Create Root CA, which would then be used to sign Intermediate CAs.
    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    # Create Intermediate CA for each cluster. All clusters have their own
    # certs for security reason.
    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk dolphin-cacerts

    # Get back to previous directory
    popd > /dev/null

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
    #
    # The below commands are for Dolphin cluster.
    kubectl create namespace --context kind-dolphin istio-system
    kubectl create secret --context kind-dolphin \
        generic cacerts -n istio-system \
        --from-file=./certs/dolphin/ca-cert.pem \
        --from-file=./certs/dolphin/ca-key.pem \
        --from-file=./certs/dolphin/root-cert.pem \
        --from-file=./certs/dolphin/cert-chain.pem
}
```

</details>

---

### 3. Install Istio into clusters

```bash
{
    istioctl install --context kind-armadillo -f clusters/armadillo/istioctl-input.yaml
    istioctl install --context kind-bison -f clusters/bison/istioctl-input.yaml
    istioctl install --context kind-dolphin -f clusters/dolphin/istioctl-input.yaml
}
```

<details>
<summary>Details</summary>

Install Istio into each cluster. Istio can be installed in a few ways, but `istioctl install` is the most standard way recommended by the official documentation. It is also possible to create a lengthy YAML definition, so that we can even have GitOps as a part of Istio installation.

As to the configurations, Armadillo and Bison have almost identical cluster setup. The main difference is the name used by various components (Ingress and Egress Gateways have `armadillo-` or `bison-` prefix, and so on). Also, as the previous step created the KinD cluster with different NodePort for Istio IngressGateway, you can see the corresponding port being used in `istioctl-input.yaml`.

</details>

---

### 4. Install Debug Processes

```bash
{
    kubectl label --context kind-armadillo namespace default istio-injection=enabled
    kubectl apply --context kind-armadillo \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl label --context kind-bison namespace default istio-injection=enabled
    kubectl apply --context kind-bison \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl label --context kind-dolphin namespace default istio-injection=enabled
    kubectl apply --context kind-dolphin \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml
}
```

<details>
<summary>Details</summary>

There are 3 actions happening, and for 3 clusters (Armadillo, Bison, and Dolphin).

Firstly, `kubectl label namespace default istio-injection=enabled` marks that namespace (in this case `default` namespace) as Istio Sidecar enabled. This means any Pod that gets created in this namespace will go through Istio's MutatingWebhook, and Istio's Sidecar component (`istio-proxy`) will be embedded into the same Pod. Without this setup, you will need to add Sidecar separately by running `istioctl` commands, which may be ok for testing, but certainly not scalable.

Second action is to install the testing tools. `httpbin` is a nice Web server which can handle incoming HTTP request and return arbitrary output based on the input path. `toolkit-alpine` is a lightweight container which has a few tools useful for testing, such as `curl`, `dig`, etc.

</details>

---

### 5. Apply Istio Custom Resources

Each cluster has different resources. Check out the documentation one by one.

<details>
<summary>For Armadillo</summary>

#### 5.1. Add `istiocoredns` as a part of CoreDNS ConfigMap

```bash
{
    export ARMADILLO_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc \
        --context kind-armadillo \
        -n istio-system \
        istiocoredns \
        -o jsonpath={.spec.clusterIP})
    echo $ARMADILLO_ISTIOCOREDNS_CLUSTER_IP
}
```

```sh
# OUTPUT
10.xx.xx.xx
```

```bash
{
    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP/" \
        clusters/armadillo/coredns-configmap.yaml
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/armadillo-services.yaml \
        -f clusters/armadillo/coredns-configmap.yaml
}
```

```sh
# OUTPUT
Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
configmap/coredns configured
```

<details>
<summary>Details</summary>

Istio's `istiocoredns` handles DNS lookup, and thus, you need to let Kubernetes know that `istiocoredns` gets the DNS request. Get the K8s Service cluster IP in `ARMADILLO_ISTIOCOREDNS_CLUSTER_IP` env variable, so that you can use that in `coredns-configmap.yaml` as the endpoint.

This will then be applied to `kube-system/coredns` ConfigMap. As KinD comes with CoreDNS as the default DNS and its own ConfigMap, you will see a warning about the original ConfigMap being overridden with the custom one. This is fine for testing, but you may want to carefully examine the DNS setup as that could have significant impact.

</details>

---

#### 5.2. Add ServiceEntry for Bison

Before completing this, make sure the cluster Bison is also started, and has completed Istio installation.

```bash
{
    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    echo $ARMADILLO_EGRESS_GATEWAY_ADDRESS
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/bison-connections.yaml
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
    echo $BISON_INGRESS_GATEWAY_ADDRESS
    {
        sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
            clusters/armadillo/bison-connections.yaml
        if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32002/" \
                clusters/armadillo/bison-connections.yaml
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
    -f clusters/armadillo/bison-connections.yaml
```

```sh
# OUTPUT
serviceentry.networking.istio.io/bison-services created
```

<details>
<summary>Details</summary>

**WARNING**: The current setup does NOT go through EgressGateway, and simply skips it. This needs further investigation.

There are 2 places that are being updated in a single file `clusters/armadillo/bison-connections.yaml`. The first one is for Armadillo's EgressGateway, and the second is for Bison's IngressGateway. This means the traffic follows the below pattern.

```
[ Armadillo Cluster]                                  Cluster Border                                         [ Bison Cluster]
                                                             |
App Container A ==> Istio Sidecar Proxy ==> Egress Gateway ==|==> Ingress Gateway ==> Istio Sidecar Proxy ==> App Container B
                                                             |
```

This means that, when you need App Container A to talk to App Container B on the other cluster, you need to provide 2 endpoints.

In order for 2 KinD clusters to talk to each other, the extra `sed` takes place to fallback to use `172.18.0.1` as endpoint address (which is a mapping outside of cluster), and because Bison's Ingress Gateway is set up with NodePort of `32002`, we replace the default port of `15443` with `32002`.

The command may look confusing, but the update is simple. If you cloned this repo at the step 0, you can easily see from git diff.

</details>

---

#### 5.3. Add ServiceEntry for Dolphin

Before completing this, make sure the cluster Dolphin is also started, and has completed Istio installation.

```bash
{
    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    echo $ARMADILLO_EGRESS_GATEWAY_ADDRESS
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/dolphin-connections.yaml
}
```

```sh
# OUTPUT
10.xx.xx.xx
```

```bash
{
    export DOLPHIN_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-dolphin \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    echo $DOLPHIN_INGRESS_GATEWAY_ADDRESS
    {
        sed -i '' -e "s/REPLACE_WITH_DOLPHIN_INGRESS_GATEWAY_ADDRESS/$DOLPHIN_INGRESS_GATEWAY_ADDRESS/g" \
            clusters/armadillo/dolphin-connections.yaml
        if [[ $DOLPHIN_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32004/" \
                clusters/armadillo/dolphin-connections.yaml
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
    -f clusters/armadillo/dolphin-connections.yaml
```

```sh
# OUTPUT
serviceentry.networking.istio.io/dolphin-services created
```

<details>
<summary>Details</summary>

To be updated

</details>

---

</details>

<details>
<summary>For Bison</summary>

```bash
kubectl apply --context kind-bison \
    -f clusters/bison/bison-services.yaml \
    -f clusters/bison/multicluster-setup.yaml
```

If you are using Istio v1.6, you will get an error from the above. You need to run the following command:

```bash
kubectl apply --context kind-bison \
    -f clusters/bison/multicluster-setup-1.6.yaml
```

<details>
<summary>Details</summary>

To be updated

</details>

</details>

<details>
<summary>For Dolphin</summary>

```bash
kubectl apply --context kind-dolphin \
    -f clusters/dolphin/dolphin-services.yaml \
    -f clusters/dolphin/multicluster-setup.yaml
```

If you are using Istio v1.6, you will get an error from the above. You need to run the following command:

```bash
kubectl apply --context kind-bison \
    -f clusters/bison/multicluster-setup-1.6.yaml
```

<details>
<summary>Details</summary>

To be updated

</details>

</details>

---

### 6. Verify

Simple curl to verify connection

```bash
kubectl exec \
    --context kind-armadillo \
    -it \
    $(kubectl get pod \
        --context kind-armadillo \
        -l app=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- curl -vvv httpbin.default.bison.global:8000/status/418
```

Interactive shell from Armadillo cluster

```bash
kubectl exec \
    --context kind-armadillo \
    -it \
    $(kubectl get pod --context kind-armadillo -l app=toolkit-alpine -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- bash
```

For logs

```bash
kubectl logs \
    --context kind-armadillo \
    $(kubectl get pod \
        --context kind-armadillo \
        -l app=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c istio-proxy \
    | less
```

<details>
<summary>Details</summary>

`kubectl exec -it` is used to execute some command from the main container deployed from 4. Install Debug Processes.

The verification uses `curl` to connect from Armadillo's "toolkit" to Bison's "httpbin". The address here `httpbin.default.bison.global` is intentionally different from the Istio's official guidance of `httpbin.default.global`, as this would be important if you need to connect more than 2 clusters to form the mesh. This address of `httpbin.default.bison.global` can be pretty much anything you want, as long as you have the proper conversion logic defined in the target cluster - in this case Bison.

_TODO: More to be added_

</details>

---

## Quicker Guide

The below will be quicker than above if you use multiple terminals to run them in parallel.

<details>
<summary>Details</summary>

### Prep - run before all

```bash
{
    pushd certs > /dev/null

    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk dolphin-cacerts

    popd > /dev/null
}
```

### Armadillo

**NOTE**: Armadillo has a dependency to Bison and Dolphin, so set up those clusters first.

```bash
{
    kind create cluster --config ./tools/kind-config/config-1-node-port-32001.yaml --name armadillo

    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./certs/armadillo/ca-cert.pem \
        --from-file=./certs/armadillo/ca-key.pem \
        --from-file=./certs/armadillo/root-cert.pem \
        --from-file=./certs/armadillo/cert-chain.pem

    istioctl install --context kind-armadillo -f clusters/armadillo/istioctl-input.yaml

    kubectl label --context kind-armadillo namespace default istio-injection=enabled
    kubectl apply --context kind-armadillo \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    export ARMADILLO_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc \
        --context kind-armadillo \
        -n istio-system \
        istiocoredns \
        -o jsonpath={.spec.clusterIP})
    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP/" \
        clusters/armadillo/coredns-configmap.yaml
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/armadillo-services.yaml \
        -f clusters/armadillo/coredns-configmap.yaml

    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/bison-connections.yaml
    export BISON_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-bison \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/bison-connections.yaml
    if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
        sed -i '' -e "s/15443 # Istio Ingress Gateway port/32002/" \
            clusters/armadillo/bison-connections.yaml
    fi
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/bison-connections.yaml

    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/dolphin-connections.yaml
    export DOLPHIN_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-dolphin \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    sed -i '' -e "s/REPLACE_WITH_DOLPHIN_INGRESS_GATEWAY_ADDRESS/$DOLPHIN_INGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/dolphin-connections.yaml
    if [[ $DOLPHIN_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
        sed -i '' -e "s/15443 # Istio Ingress Gateway port/32004/" \
            clusters/armadillo/dolphin-connections.yaml
    fi
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/dolphin-connections.yaml
}
```

### Bison

```bash
{
    kind create cluster --config ./tools/kind-config/config-1-node-port-32002.yaml --name bison

    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./certs/bison/ca-cert.pem \
        --from-file=./certs/bison/ca-key.pem \
        --from-file=./certs/bison/root-cert.pem \
        --from-file=./certs/bison/cert-chain.pem

    istioctl install --context kind-bison -f clusters/bison/istioctl-input.yaml

    kubectl label --context kind-bison namespace default istio-injection=enabled
    kubectl apply --context kind-bison \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl apply --context kind-bison \
        -f clusters/bison/bison-services.yaml \
        -f clusters/bison/multicluster-setup.yaml
}
```

### Dolphin

```bash
{
    kind create cluster --config ./tools/kind-config/config-1-node-port-32004.yaml --name dolphin

    kubectl create namespace --context kind-dolphin istio-system
    kubectl create secret --context kind-dolphin \
        generic cacerts -n istio-system \
        --from-file=./certs/dolphin/ca-cert.pem \
        --from-file=./certs/dolphin/ca-key.pem \
        --from-file=./certs/dolphin/root-cert.pem \
        --from-file=./certs/dolphin/cert-chain.pem

    istioctl install --context kind-dolphin -f clusters/dolphin/istioctl-input.yaml

    kubectl label --context kind-dolphin namespace default istio-injection=enabled
    kubectl apply --context kind-dolphin \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl apply --context kind-dolphin \
        -f clusters/dolphin/dolphin-services.yaml \
        -f clusters/dolphin/multicluster-setup.yaml
}
```

</details>

---

## Cleanup

```bash
{
    rm -rf certs
    git reset --hard
    kind delete cluster --name armadillo
    kind delete cluster --name bison
    kind delete cluster --name dolphin
}
```

<details>
<summary>Details</summary>

Remove the entire `certs` directory, and `git reset --hard` to remove all the changes.

KinD clusters can be deleted with `kind delete cluster` - and you can provide `--name` to specify one.

As the above steps creates multiple clusters, this step makes sure to delete all.

Because all the Istio components are inside KinD cluster, deleting the cluster will remove everything that was generated / configured / deployed.

</details>
