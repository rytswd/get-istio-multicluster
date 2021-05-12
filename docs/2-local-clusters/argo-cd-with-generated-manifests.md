# Argo CD based Setup

## 📝 What You Get from This Setup

Argo CD based setup uses the power of GitOps to wire up many components at once.

This setup would create 2 local KinD clusters, `armadillo` and `bison`.

The components included in each cluster is:

- Istio Control Plane (`istiod`)
- Istio IngressGateway x3 + Istio EgressGateway x2
- Argo CD
- Prometheus, deployed with [`prometheus-operator`](https://github.com/prometheus-operator/prometheus-operator)
- Grafana, deployed based on https://github.com/grafana/helm-charts
- Kiali, deployed with [`kiali-operator`](https://github.com/kiali/kiali-operator)
- Jaeger, deployed with [`jaeger-operator`](https://github.com/jaegertracing/jaeger-operator)
- Other debugging tools such as `httpbin`, [`color-svc`](color-svc), [`toolkit-alpine`](toolkit-alpine), etc.

Istio provides demo setup of Observability tools such as Prometheus, but they are not meant to be used for production use cases. This GitOps setup allows complex configurations of each component in the recommended deployment for each project. Because all the setup is declarative and provided in this repository as YAML files, they can work as a reference point, while keeping the deployment very simple. Once you deploy Argo CD, it would pull in all the YAML files of above tools, and apply them automatically. Argo CD would then watch for any change in the Git repository, allowing any upgardes, even including Argo CD and Istio, to take place without any imperative commands.

This declarative approach is the power of GitOps, but when it comes to starting up a cluster, there are some imperative conifgurations required. Once you complete all the steps in this guide, any configuration changes after that can happen on the YAML files in this repository. Please note that, those imperative configuration steps can result in a declarative file and be kept in the Git repository. This repository tries to keep those imperatively created files out of scope, so that anyone can clone this repository to follow the steps to get Istio Multicluster in action.

[color-svc]: https://github.com/rytswd/color-svc
[toolkit-alpine]: https://github.com/rytswd/docker-toolkit-images

## 🗃 Versions

Istio versions supported in this setup:

- v1.7.8
- v1.8.5
- v1.9.4 (To be confirmed)

Also, this setup supports Istio canary upgrade. You can find more in [`/clusters/armadillo/istio/installation/generated-manifests/kustomization.yaml`](/clusters/armadillo/istio/installation/generated-manifests/kustomization.yaml).

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

### 1. Prepare GitHub Token

<!-- == imptr: prep-github-token / begin from: ../snippets/steps/prep-github-token.md#[generate-github-token] == -->

In order for GitOps engine to sync with a remote repository like this one, you will need to prepare GitHub Personal Access Token ready.

Go to https://github.com/settings/tokens, and generate a new token.

<details>
<summary>ℹ️ Details</summary>

GitOps engine such as Argo CD will be running within a Kubernetes cluster. In case of Argo CD, it will try to fetch the configurations, which, for this repo, would be `https://github.com/rytswd/get-istio-multicluster`. At that point, it would need some credential so that it can actually access GitHub and retrieve all the relevant files. For this repo to work in GitOps manner, this step is absolutely necessary.

As to how the token works, you can find more in [the official documentation of GitHub access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

</details>

<!-- == imptr: prep-github-token / end == -->

---

### 2. Start local Kubernetes clusters with KinD

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

### 3. Prepare CA Certs

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

<details>
<summary>📝 NOTE: GitOps Consideration</summary>

<!-- == imptr: gitops-consideration / begin from: ../snippets/steps/prep-cert.md#[gitops-consideration] == -->

In truly GitOps setup, you will want to keep secrcets as a part of Git repo. That would pose another challenge on how you securely store the secret data in Git, while keeping its secrecy.

One solution is to use solution such as [sealed-secret](https://github.com/bitnami-labs/sealed-secrets), so that you can use Git to store credentials while keeping it secure.

Another approach would be to use completely separate logic for pulling secrets from external source such as KMS or [Vault](https://www.vaultproject.io/).

This is an extremely important aspect to consider when setting up production environment. Do NOT simply store credentials such as certs and GitHub access token in Git, because if you do, you will be leaking the token forever, as Git keeps the commit history.

<!-- == imptr: gitops-consideration / end == -->

</details>

---

### 4. Intsall and Configure MetalLB

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

### 5. Install Argo CD

#### Set GitHub Token

<!-- == imptr: install-argo-cd-prerequisite / begin from: ../snippets/steps/install-argo-cd.md#[prerequisite] == -->

In order to follow the below steps, it is assumed you have your GitHub Token in the env variable.

```bash
$ export userToken=<GITHUB_USER_TOKEN_FROM_STEP>
```

<!-- == imptr: install-argo-cd-prerequisite / end == -->

#### Armadillo

<!-- == imptr: install-argo-cd-armadillo / begin from: ../snippets/steps/install-argo-cd.md#[armadillo] == -->

```bash
{
    pushd clusters/armadillo/argocd > /dev/null

    kubectl apply \
        --context kind-armadillo \
        -f ./init/namespace-argocd.yaml
    kubectl create secret generic access-secret -n argocd \
        --context kind-armadillo \
        --from-literal=username=placeholder \
        --from-literal=token=$userToken
    kubectl apply -n argocd \
        --context kind-armadillo \
        -f ./installation/argo-cd-install.yaml

    kubectl patch secret argocd-secret -n argocd \
        --context kind-armadillo \
        -p \
            "{\"data\": \
                    {\
                    \"admin.password\": \"$(echo -n '$2a$10$p9R9u6JBwOVTPa3tpcS68OifxvqIPjCFceiLul2aPwOaIlEJ6fGMi' | base64)\", \
                    \"admin.passwordMtime\": \"$(date +%FT%T%Z | base64)\" \
            }}"

    popd > /dev/null
}
```

<!-- == imptr: install-argo-cd-armadillo / end == -->

#### Bison

<!-- == imptr: install-argo-cd-bison / begin from: ../snippets/steps/install-argo-cd.md#[bison] == -->

```bash
{
    pushd clusters/bison/argocd > /dev/null

    kubectl apply \
        --context kind-bison \
        -f ./init/namespace-argocd.yaml
    kubectl -n argocd create secret generic access-secret \
        --context kind-bison \
        --from-literal=username=placeholder \
        --from-literal=token=$userToken
    kubectl apply -n argocd \
        --context kind-bison \
        -f ./installation/argo-cd-install.yaml

    kubectl patch secret argocd-secret -n argocd \
        --context kind-bison \
        -p \
            "{\"data\": \
                    {\
                    \"admin.password\": \"$(echo -n '$2a$10$p9R9u6JBwOVTPa3tpcS68OifxvqIPjCFceiLul2aPwOaIlEJ6fGMi' | base64)\", \
                    \"admin.passwordMtime\": \"$(date +%FT%T%Z | base64)\" \
            }}"

    popd > /dev/null
}
```

<!-- == imptr: install-argo-cd-bison / end == -->

<details>
<summary>ℹ️ Details</summary>

<!-- == imptr: install-argo-cd-details / begin from: ../snippets/steps/install-argo-cd.md#[details] == -->

```bash
{
    # Get into cluster's directory.
    # This one is taken from Armadillo installation.
    pushd clusters/armadillo/argocd > /dev/null

    # Create namespace for Argo CD. The default installation assumes Argo CD is
    # installed under argocd namespace, and thus the same is applied here.
    kubectl apply \
        --context kind-armadillo \
        -f ./init/namespace-argocd.yaml
    # Create Kubernetes Secret of GitHub Token. This is a naïve approach, and
    # is not production ready. With token, you shouldn't need any other
    # information in the secret, but there used to be some issue with missing
    # username. For that reason, although username isn't actually used,
    # providing a placeholder as a part of Secret.
    kubectl create secret generic access-secret -n argocd \
        --context kind-armadillo \
        --from-literal=username=placeholder \
        --from-literal=token=$userToken
    # Install Argo CD. You can find more about the installation spec in
    #   /clusters/armadillo/argocd/installation/README.md
    kubectl apply -n argocd \
        --context kind-armadillo \
        -f ./installation/argo-cd-install.yaml

    # Patch Argo CD's default secret. This updates the admin password.
    # Obviously, this is not recommended for production use case, and it is
    # even recommended to disable the default admin access once the initial
    # configuration is complete.
    kubectl patch secret argocd-secret -n argocd \
        --context kind-armadillo \
        -p \
            "{\"data\": \
                    {\
                    \"admin.password\": \"$(echo -n '$2a$10$p9R9u6JBwOVTPa3tpcS68OifxvqIPjCFceiLul2aPwOaIlEJ6fGMi' | base64)\", \
                    \"admin.passwordMtime\": \"$(date +%FT%T%Z | base64)\" \
            }}"

    # Get back to the previous directory.
    popd > /dev/null
}
```

**NOTE**: `kubectl patch` against `argocd-secret` updates the login password to `admin`.

<!-- == imptr: install-argo-cd-details / end == -->

</details>

---

### Before 6. Install Istio Control Plane into Clusters

In order to speed up the deployment, it is recommended to install Istio before going ahead with GitOps configuartion.

The next step will install Argo CD drive Git repository sync, and that would override Istio installation. The same step is taken for Argo CD itself.

```bash
{
    kubectl apply \
        --context kind-armadillo \
        -f ./clusters/armadillo/istio/installation/generated-manifests/1.7.8/without-revision/istio-control-plane-install.yaml \
        -f ./clusters/armadillo/istio/installation/generated-manifests/1.7.8/without-revision/istio-multicluster-gateways-install.yaml \
        -f ./clusters/armadillo/istio/installation/generated-manifests/1.7.8/without-revision/istio-external-gateways-install.yaml \
        -f ./clusters/armadillo/istio/installation/generated-manifests/1.7.8/without-revision/istio-management-gateway-install.yaml

    kubectl apply \
        --context kind-bison \
        -f ./clusters/bison/istio/installation/generated-manifests/1.7.8/without-revision/istio-control-plane-install.yaml \
        -f ./clusters/bison/istio/installation/generated-manifests/1.7.8/without-revision/istio-multicluster-gateways-install.yaml \
        -f ./clusters/bison/istio/installation/generated-manifests/1.7.8/without-revision/istio-external-gateways-install.yaml \
        -f ./clusters/bison/istio/installation/generated-manifests/1.7.8/without-revision/istio-management-gateway-install.yaml
}
```

<details>
<summary>ℹ️ Details</summary>

Argo CD takes a look at the Git repository, and tries to apply configurations all at once. This means, with this repository, it will try to apply Istio itself, debug process, Istio Custom Resources, Observability tooling, etc. In most cases, this is expected of GitOps, but there is one complication when doing so with Istio. Istio works with having a sidecar component into each Pod, and thus, if Istio is installed Pods have been fully started, Istio won't have a chance to inject the sidecar Pod. You can stop already running Pod in order for Istio to inject the sidecar, but if you have many components, this can be tedious and time consuming.

For that reason, if you install Istio before GitOps integration takes place, you can ensure Istio can inject the sidecar into newly deployed Pods. Also, it is worth mentioning that, when Argo CD configurations in this repository are applied, Argo CD will find already running Istio, and take over its management from there on. This is because Argo CD `Application` Custom Resource is defined to install Istio in this repository, and when Argo CD reconciles the spec, it would first check for already running Istio.

This means, although this step is rather an imperative step which seemmingly does not fit in GitOps setup, it is only imperative until Argo CD custom configurations are applied. Also, if you update Istio spec in Git repository after completing the next step, it would be picked up by Argo CD, and you do not need to run `kubectl apply` anymore.

</details>

<details>
<summary>ℹ️ Note about External IP</summary>

Istio Ingress Gateway is created with `type: LoadBalancer` by default. This means that External IP will be associated with the Service, allowing Istio to handle incoming traffic from outside the mesh / cluster.

In this document, it is assumed that the cluster is KinD, and IP ranges are matching what MetalLB configuration above is using. If you are seeing different IP ranges for your Docker environment, you need to ensure your GitOps driven YAML files are also in line to have the corresponding IPs.

For example, the following is the YAML file snippet for Armadillo Multicluster Gateway

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: bison-istio-multicluster-gateways
  # ... snip ...
spec:
  # Profile empty is used to create Gateways only.
  profile: empty

  components:
    # ... snip ...
    ingressGateways:
      - enabled: true
        name: bison-multicluster-ingressgateway
        label:
          app: bison-multicluster-ingressgateway
        k8s:
          service:
            # This is assuming that you are using MetalLB with KinD. Your KinD
            # network may be differently set up, and in that case, you would
            # need to adjust this LB IP and also MetalLB IP ranges.
            # In real use cases, you will likely want to create an LB IP
            # beforehand, and use that IP here.
            loadBalancerIP: 172.18.102.150
```

This setup allows declarative setup even for LB IP, and also wiring up multiple clusters is made easier. But as this depends on your running environment, if you are seeing some unexpected traffic errors, you would want to double chcek if the IPs are associated correctly.

</details>

---

### Before 6. Part 2 - Ensure `istiocoredns` setup

#### 📍 WARNING 📍

> This step is NOT a part of GitOps, because there is no easy way to have it in a declarative manner, due to the cluster IP associated with `istiocoredns` is only confirmed once the Service is created. However, if you are trying to have GitOps setup similar to this repository, you can follow the below instructions, and then place `coredns-configmap.yaml` file as a part of GitOps.  
> Also, it's worth mentioning that `istiocoredns` is not recommended for newer version of Istio (v1.8+). This step is here to provide some reference point, but depending on your setup requirement and Isito version used, you could skip this part.

<details>
<summary>For Armadillo</summary>

<!-- == imptr: manual-coredns-armadillo / begin from: ../snippets/steps/handle-istio-resources-manually.md#[armadillo-coredns] == -->

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

<!-- == imptr: manual-coredns-armadillo / end == -->
</details>

<details>
<summary>For Bison</summary>

<!-- == imptr: manual-coredns-bison / begin from: ../snippets/steps/handle-istio-resources-manually.md#[bison-coredns] == -->

Get IP address of `istiocoredns` Service,

```bash
{
    export BISON_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc \
        --context kind-bison \
        -n istio-system \
        istiocoredns \
        -o jsonpath={.spec.clusterIP})
    echo "$BISON_ISTIOCOREDNS_CLUSTER_IP"
}
```

```sh
# OUTPUT
10.xx.xx.xx
```

And then apply CoreDNS configuration which includes the `istiocoredns` IP.

```bash
{
    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$BISON_ISTIOCOREDNS_CLUSTER_IP/" \
        ./clusters/bison/istio/installation/additional-setup/coredns-configmap.yaml
    kubectl apply --context kind-bison \
        -f ./clusters/bison/istio/installation/additional-setup/coredns-configmap.yaml
}
```

```sh
# OUTPUT
Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
configmap/coredns configured
```

The above example is only to update CoreDNS for Bison cluster, meaning traffic initiated from Bison cluster.

<details>
<summary>ℹ️ Details</summary>

Istio's `istiocoredns` handles DNS lookup, and thus, you need to let Kubernetes know that `istiocoredns` gets the DNS request. Get the K8s Service cluster IP in `BISON_ISTIOCOREDNS_CLUSTER_IP` env variable, so that you can use that in `coredns-configmap.yaml` as the endpoint.

This will then be applied to `kube-system/coredns` ConfigMap. As KinD comes with CoreDNS as the default DNS and its own ConfigMap, you will see a warning about the original ConfigMap being overridden with the custom one. This is fine for testing, but you may want to carefully examine the DNS setup as that could have significant impact.

The `sed` command may look confusing, but the change is very minimal and straighforward. If you cloned this repo at the step 0, you can easily see from git diff.

```diff
diff --git a/clusters/bison/istio/installation/additional-setup/coredns-configmap.yaml b/clusters/bison/istio/installation/additional-setup/coredns-configmap.yaml
index 9ffb5e8..d55a977 100644
--- a/clusters/bison/istio/installation/additional-setup/coredns-configmap.yaml
+++ b/clusters/bison/istio/installation/additional-setup/coredns-configmap.yaml
@@ -26,5 +26,5 @@ data:
     global:53 {
         errors
         cache 30
-        forward . REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP:53
+        forward . 10.96.238.217:53
     }
```

</details>

<!-- == imptr: manual-coredns-bison / end == -->

</details>

---

### 6. Add Argo CD Custom Resources

#### Armadillo

<!-- == imptr: use-argo-cd-armadillo / begin from: ../snippets/steps/use-argo-cd.md#[armadillo] == -->

```bash
{
    pushd clusters/armadillo/argocd > /dev/null

    kubectl apply -n argocd \
        --context kind-armadillo \
        -f ./init/argo-cd-project.yaml \
        -f ./init/argo-cd-app-with-istio-generated-manifests.yaml

    popd > /dev/null
}
```

<!-- == imptr: use-argo-cd-armadillo / end == -->

#### Bison

<!-- == imptr: use-argo-cd-bison / begin from: ../snippets/steps/use-argo-cd.md#[bison] == -->

```bash
{
    pushd clusters/bison/argocd > /dev/null

    kubectl apply -n argocd \
        --context kind-bison \
        -f ./init/argo-cd-project.yaml \
        -f ./init/argo-cd-app-with-istio-generated-manifests.yaml

    popd > /dev/null
}
```

<!-- == imptr: use-argo-cd-bison / end == -->

<details>
<summary>ℹ️ Details</summary>

<!-- == imptr: use-argo-cd-details / begin from: ../snippets/steps/use-argo-cd.md#[details] == -->

You can find more about Argo CD Custom Resource in the official documentation.

- https://argo-cd.readthedocs.io/en/latest/understand_the_basics/
- https://argo-cd.readthedocs.io/en/latest/core_concepts/
- https://argo-cd.readthedocs.io/en/latest/getting_started/

The important Custom Resources are:

**`Application`**:

`Application` is for Argo CD to understand which Git repository it needs to check against. You need to provide information such as URL, branch / tag, synchnonisation logic, etc. This works hand in hand with `Project` Custom Resource below.

**`AppProject` or `Project`**:

`Project` (aka `AppProject`) defines scope. It is crucial to have appropriate access control defined in GitOps solutions, and a lot is handled by `Project`, such as targetted namespace(s), resource whitelist/blacklist, etc. You can think of `Project` as a parent of `Application`, as each `Application` needs at least one `Project`.

<!-- == imptr: use-argo-cd-details / end == -->

</details>

---

### 7. Verify

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
