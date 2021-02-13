#!/bin/bash

__tools_dir=$(dirname "$0")/..
__root_dir="$__tools_dir"/..

ISTIO_VERSION=1.7.5

__temp_dir=$(mktemp -d)
pushd "$__temp_dir" >/dev/null || {
    echo "failed to change directory"
    aexit 1
}

echo "Installing Istio v$ISTIO_VERSION for istioctl"
{
    curl -sSL https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh - >/dev/null
}
PATH="$__temp_dir/istio-$ISTIO_VERSION/bin/"
echo "  Complete."

popd >/dev/null || {
    echo "failed to change directory"
    exit 1
}

for e in "armadillo" "bison" "dolphin"; do
    echo "Running istioctl manifest generate for '$e' cluster..."
    pushd "$__root_dir"/clusters/"$e"/istio/installation/no-operator-install/ >/dev/null || {
        echo "failed to change directory"
        exit 1
    }

    istioctl manifest generate \
        -f ../operator-usage/istio-control-plane.yaml \
        >./istio-control-plane-install.yaml
    istioctl manifest generate \
        -f ../operator-usage/istio-external-gateways.yaml \
        >./istio-external-gateways-install.yaml
    istioctl manifest generate \
        -f ../operator-usage/istio-multicluster-gateways.yaml \
        >./istio-multicluster-gateways-install.yaml
    echo "  Complete."

    popd >/dev/null || {
        echo "failed to change directory"
        exit 1
    }
done

# Clean up Istio installation
/bin/rm -rf "$__temp_dir"
