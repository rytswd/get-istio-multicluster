#!/bin/bash

__tools_dir=$(dirname "$0")/..
__root_dir="$__tools_dir"/..

for e in "armadillo" "bison" "dolphin"; do
    curl -sSL "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.45.0/bundle.yaml" \
        >"$__root_dir"/clusters/$e/observability/prometheus-operator/prometheus-operator-install.yaml
done
