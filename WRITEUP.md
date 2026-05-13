# Capstone Write-Up: Acme Health Patient Intake API — CMMC L2

## Framework Choice

**Primary framework: CMMC Level 2 (NIST 800-171 rev 3)**

Acme Health handles Protected Health Information (PHI) through a Patient Intake API. While HIPAA and SOC 2 were considered, CMMC L2 was selected because the federal pilot opportunity requires it, its controls are technically specific and testable in code, and NIST 800-171 maps directly to the gaps identified in GAPS.md. Every policy, Terraform resource, and OSCAL component in this repo cites a CMMC L2 practice ID.

## Gap Remediation

| Gap | Control | Remediation Layer | Resource |
|-----|---------|-------------------|----------|
| GAP-01 | SC.L2-3.13.11 | Terraform | `aws_s3_bucket_server_side_encryption_configuration.uploads` with `aws:kms` |
| GAP-02 | SC.L2-3.13.11 | Terraform | `aws_dynamodb_table.intake` with `server_side_encryption` CMK block |
| GAP-03 | SC.L2-3.13.8 | Terraform + Policy | `aws_s3_bucket_policy.uploads_tls` denying `aws:SecureTransport=false` |
| GAP-04 | MP.L2-3.8.9 | Terraform + Policy | `aws_s3_bucket_versioning.uploads` with `status = Enabled` |
| GAP-05 | SC.L2-3.13.1 | Terraform | `aws_security_group.lambda` created; vpc_config documented as next step |
| GAP-07 | AC.L2-3.1.5 | Terraform + Policy | Removed `dynamodb:*` and `s3:*`; replaced with `lambda_least_privilege` |
| GAP-08 | AU.L2-3.3.1 | Terraform + Policy | `aws_cloudtrail.mgmt` multi-region with log file validation |

GAP-06 (DLQ, reserved concurrency, X-Ray) was documented but not closed — see Trade-offs section.

## Design Decisions

**KMS key separation:** Two CMKs — one for PHI data (`aws_kms_key.phi`) and one for the evidence vault (`aws_kms_key.evidence`). This limits blast radius if one key is compromised and satisfies SC.L2-3.13.11 independently for each data store.

**GOVERNANCE vs COMPLIANCE mode:** Evidence vault uses GOVERNANCE mode with 1-day retention for lab purposes. Production would use COMPLIANCE mode with 365-day retention. GOVERNANCE allows cleanup during development; COMPLIANCE provides the strongest immutability guarantee.

**S3 backend for Terraform state:** Added S3 backend so state persists between CI runs. Without this, each pipeline run would plan to recreate all resources.

**Policy-gate as fail-closed:** Conftest runs five CMMC L2 policies on every push. A single failure blocks the pipeline. The deny messages include the control ID and remediation step so developers can fix violations without filing a GRC ticket.

## Evidence Chain

Every pipeline run produces:
1. `plan.json` — Terraform plan output
2. `conftest-results.json` — Policy gate results
3. `tfsec.sarif` — Security scan results
4. Signed bundle uploaded to `s3://acme-health-intake-evidence-vault-*/runs/<run_id>/`
5. Cosign signature verified against Sigstore Rekor transparency log
6. Object Lock GOVERNANCE retention applied automatically

An assessor verifying this submission:
1. Reads `oscal/components/acme-health-intake-v1/component-definition.json`
2. Follows evidence URI to the vault
3. Runs `verify-evidence.sh <run_id>` from Lab 4-4
4. Sees `CHAIN INTACT`

## Trade-offs

**GAP-06 not fully closed:** Reserved concurrency, DLQ, and X-Ray tracing require Lambda configuration changes that were deprioritized in favor of getting the evidence pipeline working end-to-end. These would be addressed in the next sprint.

**Lambda VPC config (GAP-05):** Security group created and private subnets provisioned. Lambda `vpc_config` block not wired due to NAT gateway cost. In production, a NAT gateway would be required for Lambda internet egress from a private subnet.

**Single AWS account:** Evidence vault and workload resources share the same account. A separate evidence-vault account would provide stronger separation of duties for AU-9.

## What I Didn't Get To

- GAP-06: Lambda reserved concurrency, DLQ, X-Ray
- API Gateway WAF and throttling (GAP-08 partial)
- Separate evidence vault AWS account
- COMPLIANCE mode Object Lock for production-grade retention
- SSP (System Security Plan) — the natural next OSCAL artifact after the component definition

## Verification Instructions for the Grader

```bash
# 1. Clone the repo
git clone https://github.com/joserodriguezthe1/cgep-capstone-acme-health.git
cd cgep-capstone-acme-health

# 2. Run OPA tests
opa test -v policies/

# 3. Validate OSCAL
cd oscal
trestle validate -f component-definitions/acme-health-intake-v1/component-definition.json
trestle validate -f profiles/cmmc-l2-minimum/profile.json

# 4. Verify evidence chain (requires AWS credentials)
EVIDENCE_VAULT=acme-health-intake-evidence-vault-ab870913 \
  bash scripts/verify-evidence.sh <run_id> --profile default
```

Green PR: `green-baseline-fixes` branch — all 5 policies pass
Red PR: `red-gap-demonstration` branch — 3 policy failures demonstrating gate works