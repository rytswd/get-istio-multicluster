The installation file `istio-install.yaml` is created with the following command:

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ {
    istioctl manifest generate --context kind-armadillo \
        -f clusters/armadillo/istio-setup/istio-control-plane.yaml \
            > clusters/armadillo/argocd/stack/istio/istio-control-plane.yaml
    istioctl manifest generate --context kind-armadillo \
        -f clusters/armadillo/istio-setup/istio-external-gateways.yaml \
            > clusters/armadillo/argocd/stack/istio/istio-external-gateways.yaml
    istioctl manifest generate --context kind-armadillo \
        -f clusters/armadillo/istio-setup/istio-multicluster-gateways.yaml \
            > clusters/armadillo/argocd/stack/istio/istio-multicluster-gateways.yaml
}
```
