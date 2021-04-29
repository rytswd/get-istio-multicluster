# GitHub Token Preparation

GitOps is a Kubernetes cluster management approach, which relies on Git as the single source of truth.

Assuming that your Git repository is on GitHub, you need to prepare the relevant token.

## Prepare GitHub Token

<!-- == export: generate-github-token / begin == -->

In order for GitOps engine to sync with a remote repository like this one, you will need to prepare GitHub Personal Access Token ready.

Go to https://github.com/settings/tokens, and generate a new token.

<details>
<summary>ℹ️ Details</summary>

GitOps engine such as Argo CD will be running within a Kubernetes cluster. In case of Argo CD, it will try to fetch the configurations, which, for this repo, would be `https://github.com/rytswd/get-istio-multicluster`. At that point, it would need some credential so that it can actually access GitHub and retrieve all the relevant files. For this repo to work in GitOps manner, this step is absolutely necessary.

As to how the token works, you can find more in [the official documentation of GitHub access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

</details>

<!-- == export: generate-github-token / end == -->
