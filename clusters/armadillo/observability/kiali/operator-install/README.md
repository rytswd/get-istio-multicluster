# Kiali Operator Install

Run the following to get the Operator installation manifest.

This installation assumes that namespace `kiali-operator` exists.

```sh
$ helm template \
    --include-crds \
    --set cr.namespace=istio-system \
    --namespace kiali-operator \
    --repo https://kiali.org/helm-charts \
    --version 1.29.0 \
    kiali-operator \
    kiali-operator > ./kiali-operator-install.yaml
```

NOTE: This is done as Helm dependency setup was seeing some errors.
