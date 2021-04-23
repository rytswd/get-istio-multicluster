# Use Argo CD

## Apply Argo CD Custom Resources

### For Armadillo

<!-- == export: armadillo / begin == -->

```bash
{
    pushd clusters/armadillo/argocd > /dev/null

    kubectl apply -n argocd \
        --context kind-armadillo \
        -f ./init/argo-cd-project.yaml \
        -f ./init/argo-cd-app-demo-2.yaml

    popd > /dev/null
}
```

<!-- == export: armadillo / end == -->

### For Bison

<!-- == export: bison/ begin == -->

```bash
{
    pushd clusters/bison/argocd > /dev/null

    kubectl apply -n argocd \
        --context kind-bison \
        -f ./init/argo-cd-project.yaml \
        -f ./init/argo-cd-app-demo-2.yaml

    popd > /dev/null
}
```

<!-- == export: bison / end == -->

## Details

<!-- == export: details / begin == -->

You can find more about Argo CD Custom Resource in the official documentation.

- https://argo-cd.readthedocs.io/en/latest/understand_the_basics/
- https://argo-cd.readthedocs.io/en/latest/core_concepts/
- https://argo-cd.readthedocs.io/en/latest/getting_started/

The important Custom Resources are:

**`Application`**:

`Application` is for Argo CD to understand which Git repository it needs to check against. You need to provide information such as URL, branch / tag, synchnonisation logic, etc. This works hand in hand with `Project` Custom Resource below.

**`AppProject` or `Project`**:

`Project` (aka `AppProject`) defines scope. It is crucial to have appropriate access control defined in GitOps solutions, and a lot is handled by `Project`, such as targetted namespace(s), resource whitelist/blacklist, etc. You can think of `Project` as a parent of `Application`, as each `Application` needs at least one `Project`.

<!-- == export: details / end == -->
