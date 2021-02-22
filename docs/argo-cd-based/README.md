# Argo CD based Setup

## 📝 Setup Details

This setup uses this remote repository as the target. If you want to adjust the installation setup as your liking, you can fork this repo, or simply copy the directory.

For detailed GitOps setup, you can find more complex setup in [get-gitops-k8s](https://github.com/rytswd/get-gitops-k8s).

## ⚙️ Prerequisites

In addition to the base prerequisite, you would need the following tools as well:

- [kubectx](https://github.com/ahmetb/kubectx)

## 🐾 Steps

### 0. Clone this repository

```bash
$ pwd
/some/path/at

$ git clone https://github.com/rytswd/get-istio-multicluster.git

$ cd get-istio-multicluster
```

From here on, all the steps are assumed to be run from `/some/path/at/get-istio-multicluster`.

<details>
<summary>Details</summary>

This repository is mostly configuration files. Having the set of files all in directory structure makes it easier to see how multiple configurations work together.

Note that this setup uses **remote Git repository**, meaning that your cloned repository on your machine won't actually drive what's being installed into the cluster. You will find more in detail in the coming steps, but if you want to take full control and make adjustments as you go, you would want to fork this repository, and replace all the `rytswd` username with your GitHub account.

</details>

---

### 1. Prepare GitHub Token

In order for Argo CD to sync to this remote repository, you will need to get your access token ready.

Go to https://github.com/settings/tokens, and create a token.

The next step will use this token.

<details>
<summary>Details</summary>

In the following steps, Argo CD will run on your local machine. Argo CD will then fetch the configurations from `https://github.com/rytswd/get-istio-multicluster` - and thus, it would need to be able to use your GitHub account credential to retrieve all the relevant files, and also automatically apply changes to your cluster.

As to how the token works, you can find more in [the official documentation of GitHub access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

</details>

---

### 2. Start local Kubernetes clusters with KinD

```bash
{
    kind create cluster --config ./tools/kind-config/v1.17/config-2-nodes-port-320x1.yaml --name armadillo
    kind create cluster --config ./tools/kind-config/v1.17/config-2-nodes-port-320x2.yaml --name bison
}
```

You can use k3d as well. This example sticks with KinD.

<details>
<summary>Details</summary>

You can find more about this setup in [KinD-based Setup document](https://github.com/rytswd/get-istio-multicluster/tree/main/docs/kind-based#1-start-local-kubernetes-clusters-with-kind).

</details>

---

### 3. Prepare CA Certs

<!-- The steps are detailed at [Certificate Preparation steps](https://github.com/rytswd/get-istio-multicluster/tree/main/docs/cert-prep/README.md). -->

You need to complete this step before installing Istio to the cluster.

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
<summary>Details</summary>

In truly GitOps setup, you will likely want to keep this secrcet as a part of git repo. That would pose another challenge on how you can securely store the secret data in git, while keeping its secrecy.

You can combine with solution such as [sealed-secret](https://github.com/bitnami-labs/sealed-secrets) to store secret securely in git.

You can find more about this setup in [KinD-based Setup document](https://github.com/rytswd/get-istio-multicluster/blob/main/docs/kind-based/README.md#2-prepare-ca-certs).

</details>

---

### 4. Install Argo CD

Armadillo

```bash
$ export userToken=GITHUB_USER_TOKEN_FROM_STEP_1
```

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

Install GitOps setup

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

Bison

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

Install GitOps setup

```bash
{
    pushd clusters/bison/argocd > /dev/null

    kubectl apply -n argocd \
        --context kind-bison \
        -f ./init/argo-cd-project.yaml \
        -f ./init/argo-cd-app-demo-2.yaml

    popd > /dev/null
}
```

<details>
<summary>Details</summary>

_To be updated_

`kubectl patch` against argocd secret updates the login password as `admin`.

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
