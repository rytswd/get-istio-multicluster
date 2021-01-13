#!/bin/bash

{
    pushd clusters/armadillo/argocd >/dev/null

    kubectl apply \
        -f ./init/namespace-argocd.yaml
    kubectl -n argocd create secret generic access-secret \
        --from-literal=username=placeholder \
        --from-literal=token=$userToken
    kubectl apply -n argocd \
        -f ./stack/argo-cd/argo-cd-install.yaml
    kubectl apply -n argocd \
        -f ./init/argo-cd-project.yaml \
        -f ./init/argo-cd-application.yaml

    popd >/dev/null
}
