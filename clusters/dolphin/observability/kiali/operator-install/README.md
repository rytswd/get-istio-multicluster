# Kiali Operator Install

Run the following to get the Operator installation manifest.

This installation assumes that namespace `kiali-operator` exists.

```sh
$ helm template \
    --include-crds \
    --values ./stack/kiali-operator/kiali-helm-values.yaml \
    --namespace kiali-operator \
    --repo https://kiali.org/helm-charts \
    --version 1.29.0 \
    kiali-operator \
    kiali-operator > ./stack/kiali-operator/kiali-operator-install.yaml
```
