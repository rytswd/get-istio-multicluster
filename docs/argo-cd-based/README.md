# Argo CD based Setup

## 📝 Setup Details

This setup uses this remote repository as the target. If you want to adjust the installation setup as your liking, you can fork this repo, or simply copy the directory.

For detailed GitOps setup, you can find more complex setup in my [get-gitops-k8s](https://github.com/rytswd/get-gitops-k8s) repo.

## ⚙️ Prerequisites

In addition to the base prerequisite, you would need the following tools as well:

- [kubectx](https://github.com/ahmetb/kubectx)

## 🐾 Steps

### 0. Clone this repository

```bash
$ pwd
/some/path/at

$ git clone https://github.com/rytswd/simple-istio-multicluster.git
```

From here on, all the steps are assumed to be run from `/some/path/at/simple-istio-multicluster`.

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

In the following steps, Argo CD will run on your local machine. Argo CD will then fetch the configurations from `https://github.com/rytswd/simple-istio-multicluster` - and thus, it would need to be able to use your GitHub account credential to retrieve all the relevant files, and also automatically apply changes to your cluster.

As to how the token works, you can find more in [the official documentation of GitHub access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

</details>

---

### 2. Start local Kubernetes clusters with KinD

```bash
{
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32001.yaml --name armadillo
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32002.yaml --name bison
    kind create cluster --config ./tools/kind-config/config-2-nodes-port-32004.yaml --name dolphin
}
```

You can use k3d as well. This example sticks with KinD.

<details>
<summary>Details</summary>

You can find more in [KinD-based Setup document](https://github.com/rytswd/simple-istio-multicluster/tree/main/docs/kind-based#1-start-local-kubernetes-clusters-with-kind).

</details>

---

### 3. Install Argo CD

Armadillo

```bash
{
    kubectx kind-armadillo
    pushd docs/argo-cd-based/gitops-armadillo
    make

    # ========================================
    #
    # Interactive mode
    #   provide your credential when requested
    #
    # ========================================

    popd
}
```

<details>
<summary>Details</summary>

Firstly, run `kubectx` to point to the correct cluster.

`pushd` and `popd` are there to change directory while `make` is running, and then get back to the original directory.

`make` runs several actions.

_To be updated_

</details>

---
