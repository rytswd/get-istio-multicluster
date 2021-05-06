# Istio Installation with Generated Manifest

This directory contains installation manifests.

## Basic Usage: `full-installation`

You should find all the installation spec under `full-installation` directory.

The resources are created using files under `operator-usage`, with the respective version of `istioctl`.

## Canary Installation: `as-canary`

Canary installation means Istio Control Plane will be installed as a canary version.

This means other Istio Control Plane components are expected to be in the cluster, and the Data Plane components will not be fully replaced with this.

## With Next Canary: `before-retiring`

When another release is being tested under canary release, there are some conflicting resources that need to be sorted before applying to the cluster.

For that reason, this `before-retiring` directory contains the same set of resources as `full-installation`, but some common resources such as duplicated ServiceAccount, Role, etc. are removed.

This may not be preferrable if the new release introduces tighter RBAC, etc., and in such a case, you should simply use `full-installation` and patch the next canary release instead.
