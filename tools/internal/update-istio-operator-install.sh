#!/bin/bash

__tools_dir=$(dirname "$0")/..
__root_dir="$__tools_dir"/..

for e in "armadillo" "bison" "dolphin"; do
    istioctl operator dump >"$__root_dir"/clusters/$e/istio-operator/istio-operator-install.yaml
done
