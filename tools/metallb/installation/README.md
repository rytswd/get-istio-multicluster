# MetalLB

```bash
{
    METALLB_VERSION="v0.9.6"

    curl -sSL "https://raw.githubusercontent.com/metallb/metallb/$METALLB_VERSION/manifests/namespace.yaml" > metallb-namespace.yaml
    curl -sSL "https://raw.githubusercontent.com/metallb/metallb/$METALLB_VERSION/manifests/metallb.yaml" > metallb-install.yaml

    echo "SHA check for 'metallb-namespace'"
    curl -sSL "https://raw.githubusercontent.com/metallb/metallb/$METALLB_VERSION/manifests/namespace.yaml" | shasum -a 256
    shasum -a 256 metallb-namespace.yaml

    echo

    echo "SHA check for 'metallb-install'"
    curl -sSL "https://raw.githubusercontent.com/metallb/metallb/$METALLB_VERSION/manifests/metallb.yaml" | shasum -a 256
    shasum -a 256 metallb-install.yaml
}
```
