# Installation Related Information

Each cluster setup under `/clusters/` has a similar directory structure.

## With Istio

### Directories

<!-- == export: with-istio-directories / begin == -->

- `additional-setup`: Some extra resources that are required for Istio to run fully. This is used only sparingly, such as the old Istio requiring its own CoreDNS for multicluster setup.
- `generated-manifests`: This holds onto all the manifests generated by `istioctl manifest generate`.
- `operator-install`: This has IstioOperator controller installation spec. The IstioOperator CustomResource for the actual installation is not included in this directory, and thus, using this directory only installs the IstioOperator controller.
- `operator-usage`: This holds onto all the IstioOperator CustomResource for Istio installation details. This is the main installation spec, and shouldn't be affected by the version of Istio you are trying to install. The CR can be installed directly to the cluster if you have the IstioOperator controller running. Or, if you want to take control of the actual manifests applied to the cluster, you can use the generated manifests which use the CR in this directory.
- `references`: Other references that are useful for managing Istio, such as a Kustomize patch file to remove duplicated resources when doing Canary upgrade.

<!-- == export: with-istio-directories / end == -->

### Details

<!-- == export: with-istio-details / begin == -->

There are several ways to install Istio into the clusters, as listed in the official document.

https://istio.io/latest/docs/setup/install/

This repository aims to provide the repository setup that works with GitOps, and because of that, there are only 2 viable options.

### Using IstioOperator Controller

IstioOperator is a Custom Resource, and also a controller which understands the Custom Resource. This section talks about the IstioOPerator controller.

This approach should feel most natural and very Kubernetes-like.

The installation of the controller can be managed by YAML definition created by `istioctl operator dump` command, and its documentation is very sparse. If you follow along the official document, you will find more about `istioctl operator init`, which does all the setup for you - but you lose the fully declarative setup that way.

After you have the Istio Operator controller running in the cluster, you can simply apply your IstioOperator Custom Resource to the cluster.

Because of the clarity you get from the declarative manifests is essentially hidden away by the controller, I personally do not recommend the use of the IstioOperator controller, especially for testing and debugging, where you want to understand more about Istio by knowing what it does. If you are comfortable with the controller handling everything for you, this is certainly a possible way.

The Operator controller was a relatively recent addition, and there were some hiccups with installation and updates. For some of the reasons mentioned above, this repository does have `operator-install` directory, but does not use it by default.

I'll be working on some documentation to use the IstioOperator controller, and when I do, I'll explicitly note about its implications in there.

### Using Generated Manifests

Generated Manifests are essentially a dump of Istio installation configuration spec. This is created by running `istioctl manifest generate` command. Compared to `istioctl install`, it comes with the limitation that the command runs completely offline and generates the YAML file you can apply to the cluster. `istioctl install`, on the other hand, can connect to the cluster, check its environment, and does extra handling for installation. For that reason, it's definitely easier to get started with `istioctl install`, but a lot of steps would be run rather imperatively, and you won't have declarative configurations in the end.

For that reason, `istioctl manifest generate` approach is taken as the basic installation setup. This means there are additional resource management required, and can be repetetive at times. This is the cost for getting everything declarative rather than having some manual action.

<!-- == export: with-istio-details / end == -->