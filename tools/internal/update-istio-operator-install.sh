#!/bin/bash

ISTIO_VERSION=1.9.4

__tools_dir=$(dirname "$0")/..
__root_dir="$__tools_dir"/..
__revision=$(echo $ISTIO_VERSION | tr '.' '-')

__temp_dir=$(mktemp -d)
pushd "$__temp_dir" >/dev/null || {
    echo "failed to change directory"
    exit 1
}

echo "Installing Istio v$ISTIO_VERSION to get istioctl..."
{
    curl -sSL https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh - >/dev/null
}
PATH="$__temp_dir/istio-$ISTIO_VERSION/bin/:$PATH"
echo "  Complete."

popd >/dev/null || {
    echo "failed to change directory"
    exit 1
}

for e in "armadillo" "bison" "dolphin"; do
    echo "Running istioctl operator dump for '$e' cluster..."

    istioctl operator dump \
        --revision "$__revision" \
        >"$__root_dir"/clusters/$e/istio/installation/operator-install/istio-operator-install-"$ISTIO_VERSION".yaml

    echo "  Complete."
done

# Clean up Istio installation
rm -rf "$__temp_dir"
