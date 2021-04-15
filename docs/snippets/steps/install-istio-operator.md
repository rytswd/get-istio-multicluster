# Install Istio Operator

## Using `istioctl`

```bash
{
    istioctl --context kind-armadillo \
        operator init \
        -f ./clusters/armadillo/istio/installation/operator-install/istio-operator-install.yaml

    istioctl --context kind-bison \
        operator init \
        -f ./clusters/bison/istio/installation/operator-install/istio-operator-install.yaml
}
```

## Using manifest

```bash
{
    kubectl apply --context kind-armadillo \
        -f ./clusters/armadillo/istio/installation/operator-install/istio-operator-install.yaml

    kubectl apply --context kind-bison \
        -f ./clusters/bison/istio/installation/operator-install/istio-operator-install.yaml
}
```

When you see error messages such as:

```console
Error from server (NotFound): error when creating "./clusters/armadillo/istio/installation/operator-install/istio-operator-install.yaml": namespaces "istio-operator" not found
```

You can simply run the above command one more time. <!--TODO: Add more details-->

## What is Istio Operator install

This prepares for Istio installation by installing IstioOperator Controller. It allows defining IsitoOperator Custom Resource in declarative manner, and IstioOperator Controller to handle the installation.

You can use `istioctl operator init` to install, or get the IstioOperator Controller installation spec with `istioctl operator dump`. In multicluster scenario, it is safer to have all clusters with the same Istio version, and thus you could technically use the same spec.

As this repository aims to be as declarative as possible, the installation specs are saved using `istioctl operator dump`, and saved under each cluster spec. You can use `get-istio-multicluster/tools/internal/update-istio-operator-install.sh` script to update all the IstioOperator Controller installation spec in one go.

---
