# Istio Operator

Istio Operator manages the Istio installation, and the operator itself can be installed with `istioctl operator init`.

As we want to ensure Istio Operator is also a part of GitOps installation, we are generating the Istio Operator installation spec with `istioctl operator dump` command.

Ref: https://github.com/rytswd/get-istio-multicluster/blob/main/tools/internal/update-istio-operator-install.sh

# Deprecated: Istio Installation with YAML

Istio recommends the use of `istioctl install`, and there is another approach of using `istioctl manifest generate` to dump YAML representation of the installation spec.
These can be created with the following command:

```bash
$ pwd
/some/path/at/get-istio-multicluster

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
