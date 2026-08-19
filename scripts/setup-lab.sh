#!/usr/bin/env bash
# One-shot local lab: create a kind cluster, install Kyverno, apply namespace + policies,
# then demonstrate that the insecure workload is BLOCKED and the hardened one is admitted.
# Requires: docker, kind, kubectl, helm
set -euo pipefail

echo "== 1. Create kind cluster =="
kind create cluster --config scripts/kind-cluster.yaml

echo "== 2. Install Kyverno (admission controller) =="
helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null 2>&1 || true
helm repo update >/dev/null
helm install kyverno kyverno/kyverno -n kyverno --create-namespace --wait

echo "== 3. Apply namespace (with restricted Pod Security Standard) and policies =="
kubectl apply -f manifests/namespace.yaml
kubectl apply -f policies/kyverno/disallow-privileged.yaml
kubectl apply -f policies/kyverno/require-non-root.yaml
kubectl apply -f policies/kyverno/disallow-host-path.yaml
kubectl apply -f policies/kyverno/require-resource-limits.yaml
kubectl apply -f rbac/hardened-app-rbac.yaml
kubectl apply -f network-policies/default-deny.yaml
kubectl apply -f network-policies/allow-app-ingress.yaml

echo
echo "== 4. Try to deploy the INSECURE pod (expect: BLOCKED by admission control) =="
kubectl apply -f manifests/insecure/privileged-pod.yaml || echo ">>> Blocked as expected."

echo
echo "== 5. Deploy the HARDENED workload (expect: admitted) =="
kubectl apply -f manifests/secure/hardened-deployment.yaml
kubectl -n workloads get deploy hardened-app

echo
echo "Capture the output of steps 4 and 5 for evidence/ and the README."
