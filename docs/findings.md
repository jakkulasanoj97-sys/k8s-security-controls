# Kubernetes Security Controls Assessment

## Executive summary

The assessment hardened a Kubernetes workload against the CIS Kubernetes Benchmark and the
Pod Security Standards (Restricted profile), and enforced those controls at admission time
with policy-as-code. An intentionally insecure workload is used to prove each control blocks
the misconfiguration it targets.

## Controls

| Control | Requirement | Enforced by |
|---------|-------------|-------------|
| CTRL-K8S-001 | No privileged containers | Kyverno + PSS restricted |
| CTRL-K8S-002 | Containers run as non-root | Kyverno + securityContext |
| CTRL-K8S-003 | No hostPath volumes | Kyverno + PSS restricted |
| CTRL-K8S-004 | CPU/memory limits required | Kyverno |
| CTRL-K8S-RBAC-001 | Service accounts least-privilege (no cluster-admin) | RBAC Role/RoleBinding |
| CTRL-K8S-NET-001 | Default-deny network policy | NetworkPolicy |

## Findings (insecure workload)

The `manifests/insecure/privileged-pod.yaml` deliberately violates four controls. Admission
control blocks it:

| Finding | Severity | Control | Evidence |
|---------|----------|---------|----------|
| Privileged container (`privileged: true`) | High | K8S-001 | Kyverno deny |
| Runs as root (`runAsUser: 0`) | High | K8S-002 | Kyverno deny |
| hostPath mount of node root (`/`) | High | K8S-003 | Kyverno deny |
| No resource limits | Medium | K8S-004 | Kyverno deny |
| ClusterRoleBinding to `cluster-admin` | Critical | K8S-RBAC-001 | RBAC review (overprivileged-example.yaml) |

## Remediation posture

Controls are enforced at admission, not detected after the fact: a privileged or root
container is rejected by the API server before it can schedule. The hardened workload
(`manifests/secure/hardened-deployment.yaml`) passes every control — non-root UID, dropped
capabilities, read-only root filesystem, seccomp RuntimeDefault, resource limits, a
least-privilege service account with token automount disabled, and default-deny networking.

## Reproduce (local, free)

```bash
./scripts/setup-lab.sh     # kind cluster + Kyverno + apply controls + block/admit demo
./scripts/trivy-scan.sh    # image vuln + manifest misconfig scan + kyverno test
```
