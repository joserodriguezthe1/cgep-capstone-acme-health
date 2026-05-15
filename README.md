# Acme Health Patient Intake API — CGE-P Capstone

A fork of [cgep-app-starter](https://github.com/GRCEngClub/cgep-app-starter) wrapped with a CMMC Level 2 compliance baseline.

## What this repo demonstrates

- **Layer 1:** Terraform baseline closing 7 of 8 gaps from GAPS.md
- **Layer 2:** 5 OPA/Conftest policies enforcing CMMC L2 controls
- **Layer 3:** GitHub Actions pipeline — Plan → Policy check → Apply → Sign → Upload
- **Layer 4:** OSCAL component definition validated with trestle

## Primary framework

**CMMC Level 2 (NIST 800-171 rev 3)**

## Quick verification

```bash
# Run OPA policy tests
opa test -v policies/

# Validate OSCAL
cd oscal
trestle validate -f component-definitions/acme-health-intake-v1/component-definition.json
trestle validate -f profiles/cmmc-l2-minimum/profile.json

# Verify evidence chain
EVIDENCE_VAULT=acme-health-intake-evidence-vault-ab870913 \
  bash scripts/verify-evidence.sh 25830120656 --profile default
```

## PR history

- ✅ Green PR: `green-baseline-fixes` — all 5 CMMC policies pass
- ❌ Red PR: `red-violation-demo` — SC.L2-3.13.8 policy failure (TLS policy removed)

## Structure

terraform/          # Baseline + gap overrides
policies/           # 5 CMMC L2 Rego policies + tests
oscal/              # Component definition + profile
.github/workflows/  # GRC gate pipeline
WRITEUP.md          # Design decisions + trade-offs
GAPS.md             # Original 8 gaps from starter

## Evidence vault

`s3://acme-health-intake-evidence-vault-9a1ffa10`

Every pipeline run uploads a signed, timestamped evidence bundle to this Object Lock vault.