# Kubernetes Security Controls

Hardening a Kubernetes workload and enforcing security controls at admission time with
policy-as-code. An intentionally insecure workload proves each control blocks the
misconfiguration it targets — the same "show it working" approach as
[iam-policy-as-code](https://github.com/jakkulasanoj97-sys/iam-policy-as-code), applied to
containers.

## What this demonstrates

- **Pod Security Standards (Restricted)** enforced at the namespace level.
- **Admission control as code** — Kyverno policies (and an OPA Gatekeeper equivalent) that
  reject privileged, root, hostPath, and unbounded-resource workloads before they schedule.
- **Least-privilege RBAC** — a namespaced, read-only service account with token automount
  disabled, plus an over-privileged anti-pattern flagged as a review finding.
- **Default-deny networking** — a NetworkPolicy that denies all ingress/egress, with an
  explicit allow for the app's expected traffic.
- **Image + manifest scanning** — Trivy for HIGH/CRITICAL CVEs and misconfigurations.

## Controls

| Control | Requirement | Enforced by |
|---------|-------------|-------------|
| CTRL-K8S-001 | No privileged containers | Kyverno + PSS restricted |
| CTRL-K8S-002 | Containers run as non-root | Kyverno + securityContext |
| CTRL-K8S-003 | No hostPath volumes | Kyverno + PSS restricted |
| CTRL-K8S-004 | CPU/memory limits required | Kyverno |
| CTRL-K8S-RBAC-001 | Service accounts least-privilege | RBAC |
| CTRL-K8S-NET-001 | Default-deny networking | NetworkPolicy |

## The demonstration

```
Insecure Pod (privileged, root, hostPath, no limits)
        │  kubectl apply
        ▼
  Kyverno admission control
        │
    BLOCKED  ✗   ← every control rejects it

Hardened Deployment (non-root, dropped caps, read-only FS, limits, least-priv SA)
        │  kubectl apply
        ▼
  Kyverno admission control
        │
    ADMITTED ✓
```

## Layout

```
k8s-security-controls/
├── manifests/
│   ├── namespace.yaml            # namespace with restricted Pod Security Standard
│   ├── insecure/                 # deliberately violates controls (should be blocked)
│   └── secure/                   # hardened workload (should be admitted)
├── policies/
│   ├── kyverno/                  # admission policies + kyverno test spec
│   └── opa/                      # OPA Gatekeeper ConstraintTemplate equivalent
├── rbac/                         # least-privilege SA + over-privileged anti-pattern
├── network-policies/             # default-deny + explicit allow
├── scripts/
│   ├── setup-lab.sh              # kind cluster + Kyverno + block/admit demo
│   ├── trivy-scan.sh             # image + manifest scanning
│   └── kind-cluster.yaml
├── docs/findings.md              # controls assessment writeup
└── .github/workflows/k8s-security-ci.yml
```

## Run it (local, free)

```bash
# Policy tests (no cluster needed) — proves policies flag the insecure workload
kyverno test policies/kyverno/

# Full lab: real cluster, real admission control blocking the insecure pod
./scripts/setup-lab.sh
```

`setup-lab.sh` spins up a local [kind](https://kind.sigs.k8s.io/) cluster (free, runs on
your laptop), installs Kyverno, applies the controls, and shows the insecure pod being
rejected while the hardened one is admitted. Capture that output as evidence.

## CI

Every push runs the Kyverno policy tests and a Trivy manifest scan via GitHub Actions.

## Author

Sanoj J — cloud & container security, policy-as-code, detection engineering.
