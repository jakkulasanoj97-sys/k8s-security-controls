#!/usr/bin/env bash
# Scan container images and Kubernetes manifests for vulnerabilities and misconfigurations.
# Requires: trivy (https://github.com/aquasecurity/trivy)
set -euo pipefail

echo "== Image vulnerability scan (HIGH/CRITICAL) =="
trivy image --severity HIGH,CRITICAL --ignore-unfixed nginxinc/nginx-unprivileged:1.27 || true

echo
echo "== Manifest misconfiguration scan =="
# Should flag the insecure manifest, pass the hardened one.
trivy config manifests/ --severity HIGH,CRITICAL

echo
echo "== Policy-as-code check (Kyverno) =="
kyverno test policies/kyverno/
