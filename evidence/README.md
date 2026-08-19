# Evidence

Capture your local lab output here after running `./scripts/setup-lab.sh`:

- `admission-blocked.txt` — the insecure pod being rejected by Kyverno
- `admission-admitted.txt` — the hardened deployment being accepted
- `trivy-scan.txt` — image and manifest scan results
- screenshots of `kubectl get events` showing the policy denials

These are your proof that the controls run against a real cluster, not just in CI.
