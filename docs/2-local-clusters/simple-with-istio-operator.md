# KinD-based Setup

## 📝 Setup Details

After following all the steps below, you would get

- 2 clusters (`armadillo`, `bison`)
- 1 mesh
- `armadillo` to send request to `bison`

This setup assumes you are using Istio 1.7.5.

## 📚 Other Setup Steps

<!-- == imptr: other-setup-steps / begin from: ../snippets/links-to-other-steps.md#2~12 == -->
<!-- == imptr: other-setup-steps / end == -->

## 🐾 Steps

### 0. Clone this repository

<!-- == imptr: full-clone / begin from: ../snippets/steps/using-this-repo.md#24~36 == -->
<!-- == imptr: full-clone / end == -->

For more information about using this repo, you can chekc out the full documentation in [Using this repo](https://github.com/rytswd/get-istio-multicluster/blob/main/docs/snippets/steps/using-this-repo.md).

---

### 1. Start local Kubernetes clusters with KinD

<!-- == imptr: kind-start / begin from: ../snippets/steps/kind-setup.md#8~29 == -->
<!-- == imptr: kind-start / end == -->

---

### 2. Prepare CA Certs

**NOTE**: You should complete this step before installing Istio to the cluster.

<!-- == imptr: cert-prep-1 / begin from: ../snippets/steps/cert-prep.md#4~45 == -->
<!-- == imptr: cert-prep-1 / end == -->

<!-- == imptr: cert-prep-2 / begin from: ../snippets/steps/cert-prep.md#47~109 == -->
<!-- == imptr: cert-prep-2 / end == -->

---

### 3. Install IstioOperator Controller into Clusters

<details>
<summary>With `istioctl`</summary>

<!-- == imptr: install-istio-operator-with-istioctl / begin from: ../snippets/steps/install-istio-operator.md#4~16 == -->
<!-- == imptr: install-istio-operator-with-istioctl / end == -->

</details>

<details>
<summary>With manifest generation</summary>

<!-- == imptr: install-istio-operator-with-manifest / begin from: ../snippets/steps/install-istio-operator.md#18~36 == -->
<!-- == imptr: install-istio-operator-with-manifest / end == -->

</details>

<details>
<summary>ℹ️ Details</summary>

<!-- == imptr: install-istio-operator-details / begin from: ../snippets/steps/install-istio-operator.md#38~44 == -->
<!-- == imptr: install-istio-operator-details / end == -->

</details>

---

### 4. Install Istio Control Plane into Clusters

<!-- == imptr: use-istio-operator-control-plane / begin from: ../snippets/steps/use-istio-operator.md#6~29 == -->
<!-- == imptr: use-istio-operator-control-plane / end == -->

---

### 5. Install Istio Data Plane (i.e. Gateways) into Clusters

<!-- == imptr: use-istio-operator-data-plane / begin from: ../snippets/steps/use-istio-operator.md#31~54 == -->
<!-- == imptr: use-istio-operator-data-plane / end == -->

---

### 6. Install Debug Processes

<!-- == imptr: deploy-debug-services / begin from: ../snippets/steps/deploy-debug-services.md#2~49 == -->
<!-- == imptr: deploy-debug-services / end == -->

---

### 7. Apply Istio Custom Resources

Each cluster has different resources. Check out the documentation one by one.

<details>
<summary>For Armadillo</summary>

#### 7.1. Add `istiocoredns` as a part of CoreDNS ConfigMap

<!-- == imptr: manual-coredns / begin from: ../snippets/steps/handling-istio-resources-manually.md#4~50 == -->
<!-- == imptr: manual-coredns / end == -->

---

#### 7.2. Add traffic routing for Armadillo local, and prepare for multicluster outbound

<!-- == imptr: manual-routing-armadillo / begin from: ../snippets/steps/handling-istio-resources-manually.md#54~92 == -->
<!-- == imptr: manual-routing-armadillo / end == -->

---

#### 7.3. Add ServiceEntry for Bison connection

<!-- == imptr: manual-multicluster-routing-armadillo / begin from: ../snippets/steps/handling-istio-resources-manually.md#94~182 == -->
<!-- == imptr: manual-multicluster-routing-armadillo / end == -->

---

</details>

<details>
<summary>For Bison</summary>

<!-- == imptr: manual-routing-bison / begin from: ../snippets/steps/handling-istio-resources-manually.md#184~213 == -->
<!-- == imptr: manual-routing-bison / end == -->

</details>

---

### 8. Verify

<!-- == imptr: verify-with-httpbin / begin from: ../snippets/steps/verify-with-httpbin.md#6~64 == -->
<!-- == imptr: verify-with-httpbin / end == -->

---

## 🧹 Cleanup

For stopping clusters

<!-- == imptr: kind-stop / begin from: ../snippets/steps/kind-setup.md#31~49 == -->
<!-- == imptr: kind-stop / end == -->

<!-- == imptr: cert-removal / begin from: ../snippets/steps/cert-prep.md#111~136 == -->
<!-- == imptr: cert-removal / end == -->
