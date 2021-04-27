# KinD-based Setup

## 📝 Setup Details

After following all the steps below, you would get

- 2 clusters (`armadillo`, `bison`)
- 1 mesh
- `armadillo` to send request to `bison`

This setup assumes you are using Istio 1.7.5.

## 📚 Other Setup Steps

<!-- == imptr: setup-steps / begin from: ../snippets/common-info.md#[setup-steps] == -->

| Step               | Description |
| ------------------ | ----------- |
| [KinD based][1]    | TBD         |
| [k3d based][2]     | TBD         |
| [Argo CD based][3] | TBD         |

[1]: https://github.com/rytswd/get-istio-multicluster/blob/main/docs/2-local-clusters/simple-with-istio-operator.md
[2]: https://github.com/rytswd/get-istio-multicluster/tree/main/docs/k3d-based/README.md
[3]: https://github.com/rytswd/get-istio-multicluster/blob/main/docs/argo-cd-based/README.md

<!-- == imptr: setup-steps / end == -->

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

For more information about using this repo, you can chekc out the full documentation in [Using this repo](https://github.com/rytswd/get-istio-multicluster/blob/main/docs/snippets/steps/use-this-repo.md).

---

### 1. Prepare GitHub Token

<!-- == imptr: prep-github-token / begin from: ../snippets/steps/prep-github-token.md#[generate-github-token] == -->

In order for GitOps engine to sync with a remote repository like this one, you will need to prepare GitHub Personal Access Token ready.

Go to https://github.com/settings/tokens, and generate a new token.

<details>
<summary>Details</summary>

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

### 4. Install Argo CD

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

### Before 5. Install Istio Control Plane into Clusters

In order to speed up the deployment, it is recommended to install Istio before going ahead with GitOps configuartion.

The next step will install Argo CD drive Git repository sync, and that would override Istio installation. The same step is taken for Argo CD itself.

```bash
{
    kubectl apply \
        --context kind-armadillo \
        -f ./clusters/armadillo/istio/installation/no-operator-install/istio-control-plane-install.yaml \
        -f ./clusters/armadillo/istio/installation/no-operator-install/istio-external-gateways-install.yaml \
        -f ./clusters/armadillo/istio/installation/no-operator-install/istio-management-gateway-install.yaml \
        -f ./clusters/armadillo/istio/installation/no-operator-install/istio-multicluster-gateways-install.yaml

    kubectl apply \
        --context kind-bison \
        -f ./clusters/bison/istio/installation/no-operator-install/istio-control-plane-install.yaml \
        -f ./clusters/bison/istio/installation/no-operator-install/istio-external-gateways-install.yaml \
        -f ./clusters/bison/istio/installation/no-operator-install/istio-management-gateway-install.yaml \
        -f ./clusters/bison/istio/installation/no-operator-install/istio-multicluster-gateways-install.yaml
}
```

<details>
<summary>ℹ️ Details</summary>

Argo CD takes a look at the Git repository, and tries to apply configurations all at once. This means, with this repository, it will try to apply Istio itself, debug process, Istio Custom Resources, Observability tooling, etc. In most cases, this is expected of GitOps, but there is one complication when doing so with Istio. Istio works with having a sidecar component into each Pod, and thus, if Istio is installed Pods have been fully started, Istio won't have a chance to inject the sidecar Pod. You can stop already running Pod in order for Istio to inject the sidecar, but if you have many components, this can be tedious and time consuming.

For that reason, if you install Istio before GitOps integration takes place, you can ensure Istio can inject the sidecar into newly deployed Pods. Also, it is worth mentioning that, when Argo CD configurations in this repository are applied, Argo CD will find already running Istio, and take over its management from there on. This is because Argo CD `Application` Custom Resource is defined to install Istio in this repository, and when Argo CD reconciles the spec, it would first check for already running Istio.

This means, although this step is rather an imperative step which seemmingly does not fit in GitOps setup, it is only imperative until Argo CD custom configurations are applied. Also, if you update Istio spec in Git repository after completing the next step, it would be picked up by Argo CD, and you do not need to run `kubectl apply` anymore.

</details>

---

### 5. Add Argo CD Custom Resources

#### Armadillo

<!-- == imptr: use-argo-cd-armadillo / begin from: ../snippets/steps/use-argo-cd.md#[armadillo] == -->

```bash
{
    pushd clusters/armadillo/argocd > /dev/null

    kubectl apply -n argocd \
        --context kind-armadillo \
        -f ./init/argo-cd-project.yaml \
        -f ./init/argo-cd-app-demo-2.yaml

    popd > /dev/null
}
```

<!-- == imptr: use-argo-cd-armadillo / end == -->

#### Bison

<!-- == imptr: use-argo-cd-bison / begin from: ../snippets/steps/use-argo-cd.md#[details] == -->

You can find more about Argo CD Custom Resource in the official documentation.

- https://argo-cd.readthedocs.io/en/latest/understand_the_basics/
- https://argo-cd.readthedocs.io/en/latest/core_concepts/
- https://argo-cd.readthedocs.io/en/latest/getting_started/

The important Custom Resources are:

**`Application`**:

`Application` is for Argo CD to understand which Git repository it needs to check against. You need to provide information such as URL, branch / tag, synchnonisation logic, etc. This works hand in hand with `Project` Custom Resource below.

**`AppProject` or `Project`**:

`Project` (aka `AppProject`) defines scope. It is crucial to have appropriate access control defined in GitOps solutions, and a lot is handled by `Project`, such as targetted namespace(s), resource whitelist/blacklist, etc. You can think of `Project` as a parent of `Application`, as each `Application` needs at least one `Project`.

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

### 8. Verify

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
