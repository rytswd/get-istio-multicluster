# KinD-bsed Setup

## 📝 Setup Details

After following all the steps below, you would get

- 2 clusters (`armadillo`, `bison`)
- 1 mesh
- `armadillo` to send request to `bison`

This setup assumes you are using Istio 1.7.5.

### Other Setup Steps

| Name                     | Description                                    |
| ------------------------ | ---------------------------------------------- |
| 2 Clusters               | This page                                      |
| 2 Clusters with Raw YAML | The same setup but does not require Git clone  |
| 3 Clusters               | Creates 3 clusters for more complicated setup. |

[3-clusters]: https://github.com/rytswd/get-istio-multicluster/tree/main/docs/kind-based/light.md

## 🐾 Steps

### 0. Clone this repository

```bash
$ pwd
/some/path/at

$ git clone https://github.com/rytswd/get-istio-multicluster.git

$ cd get-istio-multicluster
```

From here on, all the steps are assumed to be run from `/some/path/at/get-istio-multicluster`.

Also, if you need to use specific Istio version, make sure your `PATH` is set up correctly, such as:

```bash
$ PATH="$HOME/Coding/bin/istio-1.7.5/bin:$PATH"
```

<details>
<summary>Details</summary>

This repository is mostly configuration files. Having the set of files all in directory structure makes it easier to see how multiple configurations work together.

Git repository is not necessarily a must-have. Although the clean-up step uses Git features, you could use either of the following commands for even simpler use cases:

```bash
# Shallow Git clone
git clone --depth 1 -b main https://github.com/rytswd/get-istio-multicluster.git
```

```bash
# Simple curl without Git
{
    curl -sL -o get-istio-multicluster.zip https://github.com/rytswd/get-istio-multicluster/archive/main.zip
    unzip get-istio-multicluster.zip
    cd get-istio-multicluster-main
}
```

</details>

---

### 1. Start local Kubernetes clusters with KinD

```bash
{
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32001.yaml --name armadillo
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32002.yaml --name bison
}
```

<details>
<summary>Details</summary>

KinD clusters are created with 2 almost identical configurations. The configuration ensures the Kubernetes version is v1.17 with 2 nodes in place (1 for control plane, 1 for worker).

The difference between the configuration is the open port setup. Because clusters needs to talk to each other, we need them to be externally available. With KinD, external IP does not get assigned by default, and for this demo, we are using NodePort for the entry points, effectively mocking the multi-network setup.

As you can see `istioctl-input.yaml` in each cluster, the NodePort used are:

- Armadillo will set up Istio IngressGateway with 32001 NodePort
- Bison will set up Istio IngressGateway with 32002 NodePort

</details>

---

### 2. Prepare CA Certs

<!-- The steps are detailed at [Certificate Preparation steps](https://github.com/rytswd/get-istio-multicluster/tree/main/docs/cert-prep/README.md). -->

You need to complete this step before installing Istio to the cluster. Essentially, you need to run the following:

```bash
{
    pushd certs > /dev/null
    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts

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
}
```

<details>
<summary>Details</summary>

If you do not create the certificate before Istio is installed to the cluster, Istio will fall back to use its own certificate. This will cause an issue when you try to use your custom cert later on. It's best to get the cert ready first - otherwise you will likely need to run through a bunch of restarts of Istio components and others to ensure the correct cert is picked up.

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
}
```

</details>

---

### 3. Install IstioOperator Controller into Clusters

```bash
{
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/istio/installation/operator-install/istio-operator-install.yaml

    kubectl apply --context kind-bison \
        -f clusters/bison/istio/installation/operator-install/istio-operator-install.yaml
}
```

<details>
<summary>Details</summary>

Prepare for Istio installation by installing IstioOperator Controller. This allows defining IsitoOperator Custom Resource in declarative manner, and IstioOperator Controller to handle the installation.

The IstioOperator Controller installation spec is generated by `istioctl operator dump`. All the clusters are expected to be on the same Istio version, and thus could technically use the same spec. This setup is only duplicating the same file by running `get-istio-multicluster/tools/internal/update-istio-operator-install.sh`.

Using IstioOperator Coontroller is one of the few ways to install Istio. The main installation docoumentation recommends the use of `istioctl install` command, but when splitting up IstioOperator Custom Resource, this does not work as each step will remove the formerr installed setup.

`istioctl manifest generate` is another approach, and will be documented separately.

</details>

---

### 4. Install Istio Control Plane into Clusters

```bash
{
    kubectl apply --context kind-armadillo \
        -n istio-system \
        -f clusters/armadillo/istio/installation/operator-input/istio-control-plane.yaml

    kubectl apply --context kind-bison \
        -n istio-system \
        -f clusters/bison/istio/installation/operator-input/istio-control-plane.yaml
}
```

<details>
<summary>Details</summary>

As detailed in the previous step, this step simply deploys IstioOperator CustomResource to the cluster, and rely on IstioOperator Controller to deploy Istio into the cluster.

As to the configuration files, the above commands use basically identical cluster setup input.

This installation uses the IstioOperator manifest with `minimal` profile, meaning this would be used for installing Istio "Control Plane" components. They are the core copmonents of Istio to provide its rich traffic management, security, and observability features, and mainly driven by an image of `istiod` (and a few more things around it). Some more differences would be seen for "Data Plane" components, and that would be dealt in the next step.

</details>

---

### 5. Install Istio Data Plane (i.e. Gateways) into Clusters

```bash
{
    kubectl apply --context kind-armadillo \
        -n istio-system \
        -f clusters/armadillo/istio/installation/operator-input/istio-external-gateways.yaml \
        -f clusters/armadillo/istio/installation/operator-input/istio-multicluster-gateways.yaml

    kubectl apply --context kind-bison \
        -n istio-system \
        -f clusters/bison/istio/installation/operator-input/istio-external-gateways.yaml \
        -f clusters/bison/istio/installation/operator-input/istio-multicluster-gateways.yaml
}
```

<details>
<summary>Details</summary>

This step installs "Data Plane" components into the clusters, which are mainly Istio Ingress and Egress Gateways. You can think of Data Plane components as actually running service (in this case IngressGateway which is `docker.io/istio/proxyv2` image), and they will be controlled by Control Plane components (`istiod`).

The main difference in the configuration files used above is the name used by various components (Ingress and Egress Gateways have `armadillo-` or `bison-` prefix, and so on). Also, as the previous step created the KinD cluster with different NodePort for Istio IngressGateway, you can see the corresponding port being used in `istio-multicluster-gateways.yaml`.

</details>

---

### 6. Install Debug Processes

```bash
{
    kubectl label --context kind-armadillo namespace default istio-injection=enabled
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/other/httpbin.yaml \
        -f clusters/armadillo/other/color-svc-account.yaml \
        -f clusters/armadillo/other/color-svc-only-blue.yaml \
        -f clusters/armadillo/other/toolkit-alpine.yaml

    kubectl label --context kind-bison namespace default istio-injection=enabled
    kubectl apply --context kind-bison \
        -f clusters/bison/other/httpbin.yaml \
        -f clusters/bison/other/color-svc-account.yaml \
        -f clusters/bison/other/color-svc-only-red.yaml \
        -f clusters/bison/other/toolkit-alpine.yaml
}
```

<details>
<summary>Details</summary>

There are 2 actions happening, and for 2 clusters (Armadillo and Bison).

Firstly, `kubectl label namespace default istio-injection=enabled` marks that namespace (in this case `default` namespace) as Istio Sidecar enabled. This means any Pod that gets created in this namespace will go through Istio's MutatingWebhook, and Istio's Sidecar component (`istio-proxy`) will be embedded into the Pod. Without this setup, you will need to add Sidecar separately by running `istioctl` commands, which may be ok for testing, but certainly not scalable.

Second action is to install the testing tools.

- `httpbin` is essentially a copy of httpbin.org, which can handle incoming HTTP request and return arbitrary output based on the input path.
- [`color-svc`](color-svc) is a simple web server which handles incoming HTTP request, and returns some random color. The configurations used in each cluster are slightly different, and uses different set of colors.
- [`toolkit-alpine`](toolkit-alpine) is a lightweight container which has a few tools useful for testing, such as `curl`, `dig`, etc.

For both `color-svc` and `toolkit-alpine`, [`tools`](https://github.com/rytswd/get-istio-multicluster/tree/main/tools) directory has the copy of the predefined YAML files. You can find more about how they are created in their repos.

- [github.com/rytswd/color-svc](color-svc)
- [github.com/rytswd/docker-toolkit-images](toolkit-alpine)

[color-svc]: https://github.com/rytswd/color-svc
[toolkit-alpine]: https://github.com/rytswd/docker-toolkit-images

</details>

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
        clusters/armadillo/istio/installation/additional-setup/coredns-configmap.yaml
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/istio/installation/additional-setup/coredns-configmap.yaml

    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/istio/traffic-management/local/armadillo-services.yaml
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

#### 7.2. Add ServiceEntry for Bison connection

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
        clusters/armadillo/istio/traffic-management/multicluster/bison-connections.yaml
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
            clusters/armadillo/istio/traffic-management/multicluster/bison-connections.yaml
        if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32002/" \
                clusters/armadillo/istio/traffic-management/multicluster/bison-connections.yaml
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
    -f clusters/armadillo/istio/traffic-management/multicluster/bison-connections.yaml
```

```sh
# OUTPUT
serviceentry.networking.istio.io/bison-httpbin-global created
serviceentry.networking.istio.io/bison-httpbin-service created
virtualservice.networking.istio.io/bison-httpbin-chaos-routing created
```

<details>
<summary>Details</summary>

**WARNING**: The current setup does NOT go through EgressGateway, and simply skips it. This needs further investigation.

There are 2 places that are being updated in a single file `clusters/armadillo/istio/traffic-management/multicluster/bison-connections.yaml`. The first one is for Armadillo's EgressGateway, and the second is for Bison's IngressGateway. This means the traffic follows the below pattern.

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

</details>

<details>
<summary>For Bison</summary>

```bash
kubectl apply --context kind-bison \
    -f clusters/bison/istio/traffic-management/local/bison-services.yaml \
    -f clusters/bison/istio/traffic-management/multicluster/multicluster-setup.yaml
```

If you are using Istio v1.6, you will get an error from the above. You need to run the following command:

```bash
kubectl apply --context kind-bison \
    -f clusters/bison/istio/traffic-management/archive-for-istio-1.6/multicluster-setup-1.6.yaml
```

<details>
<summary>Details</summary>

To be updated

</details>

</details>

---

### 8. Verify

Simple curl to verify connection

```bash
kubectl exec \
    --context kind-armadillo \
    -it \
    $(kubectl get pod \
        --context kind-armadillo \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- curl -vvv httpbin.default.bison.global:8000/status/418
```

Interactive shell from Armadillo cluster

```bash
kubectl exec \
    --context kind-armadillo \
    -it \
    $(kubectl get pod \
        --context kind-armadillo \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- bash
```

For logs

```bash
kubectl logs \
    --context kind-armadillo \
    $(kubectl get pod \
        --context kind-armadillo \
        -l app.kubernetes.io/name=toolkit-alpine \
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

## ⚡️ Quicker Paralllel Steps

The below will be quicker than above if you use multiple terminals to run them in parallel.

TODO: THE BELOW NEEDS TO BE UPDATED

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

### Bison

```bash
{
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32002.yaml --name bison

    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./certs/bison/ca-cert.pem \
        --from-file=./certs/bison/ca-key.pem \
        --from-file=./certs/bison/root-cert.pem \
        --from-file=./certs/bison/cert-chain.pem

    istioctl install --context kind-bison -f clusters/bison/istio-setup/istioctl-input.yaml

    kubectl label --context kind-bison namespace default istio-injection=enabled
    kubectl apply --context kind-bison \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl apply --context kind-bison \
        -f clusters/bison/local/bison-services.yaml \
        -f clusters/bison/istio-setup/multicluster-setup.yaml
}
```

### Dolphin

```bash
{
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32004.yaml --name dolphin

    kubectl create namespace --context kind-dolphin istio-system
    kubectl create secret --context kind-dolphin \
        generic cacerts -n istio-system \
        --from-file=./certs/dolphin/ca-cert.pem \
        --from-file=./certs/dolphin/ca-key.pem \
        --from-file=./certs/dolphin/root-cert.pem \
        --from-file=./certs/dolphin/cert-chain.pem

    istioctl install --context kind-dolphin -f clusters/dolphin/istio-setup/istioctl-input.yaml

    kubectl label --context kind-dolphin namespace default istio-injection=enabled
    kubectl apply --context kind-dolphin \
        -f tools/httpbin/httpbin.yaml \
        -f tools/toolkit-alpine/toolkit-alpine.yaml

    kubectl apply --context kind-dolphin \
        -f clusters/dolphin/local/dolphin-services.yaml \
        -f clusters/dolphin/istio-setup/multicluster-setup.yaml
}
```

### Armadillo

**NOTE**: Armadillo has a dependency to Bison and Dolphin, so set up those clusters first.

```bash
{
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32001.yaml --name armadillo

    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./certs/armadillo/ca-cert.pem \
        --from-file=./certs/armadillo/ca-key.pem \
        --from-file=./certs/armadillo/root-cert.pem \
        --from-file=./certs/armadillo/cert-chain.pem

    istioctl install --context kind-armadillo -f clusters/armadillo/istio-setup/istioctl-input.yaml

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
        clusters/armadillo/istio-setup/coredns-configmap.yaml
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/local/armadillo-services.yaml \
        -f clusters/armadillo/istio-setup/coredns-configmap.yaml

    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/external/bison-connections.yaml
    export BISON_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-bison \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/external/bison-connections.yaml
    if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
        sed -i '' -e "s/15443 # Istio Ingress Gateway port/32002/" \
            clusters/armadillo/external/bison-connections.yaml
    fi
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/external/bison-connections.yaml

    export ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/external/dolphin-connections.yaml
    export DOLPHIN_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-dolphin \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    sed -i '' -e "s/REPLACE_WITH_DOLPHIN_INGRESS_GATEWAY_ADDRESS/$DOLPHIN_INGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/external/dolphin-connections.yaml
    if [[ $DOLPHIN_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
        sed -i '' -e "s/15443 # Istio Ingress Gateway port/32004/" \
            clusters/armadillo/external/dolphin-connections.yaml
    fi
    kubectl apply --context kind-armadillo \
        -f clusters/armadillo/external/dolphin-connections.yaml
}
```

</details>

---

## 🧹 Cleanup

```bash
{
    rm -rf certs
    git reset --hard
    kind delete cluster --name armadillo
    kind delete cluster --name bison
}
```

<details>
<summary>Details</summary>

Remove the entire `certs` directory, and `git reset --hard` to remove all the changes.

KinD clusters can be deleted with `kind delete cluster` - and you can provide `--name` to specify one.

As the above steps creates multiple clusters, this step makes sure to delete all.

Because all the Istio components are inside KinD cluster, deleting the cluster will remove everything that was generated / configured / deployed.

</details>
