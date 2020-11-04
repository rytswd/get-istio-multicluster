The installation file `istio-install.yaml` is created with the following command:

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ istioctl manifest generate --context kind-armadillo \
    -f clusters/armadillo/istioctl-input.yaml > docs/argo-cd-based/gitops-armadillo/stack/istio/istio-install.yaml
```
