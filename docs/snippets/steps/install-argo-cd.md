# Install Argo CD

## Prerequisite

<!-- == export: prerequisite / begin == -->

In order to follow the below steps, it is assumed you have your GitHub Token in the env variable.

```bash
$ export userToken=<GITHUB_USER_TOKEN_FROM_STEP>
```

<!-- == export: prerequisite / end == -->

## Install Argo CD to Armadillo cluster

<!-- == export: armadillo / begin == -->

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

<!-- == export: armadillo / end == -->

## Install Argo CD to Bison cluster

<!-- == export: bison / begin == -->

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

<!-- == export: bison / end == -->

## Details

<!-- == export: details / begin == -->

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

<!-- == export: details / end == -->
