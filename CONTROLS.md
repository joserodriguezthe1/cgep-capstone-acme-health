# Control-to-Code Mapping

Bidirectional mapping of CMMC Level 2 controls to implementing code artifacts.

## SC.L2-3.13.11 — Cryptographic Protection

**Gaps closed:** GAP-01 (S3), GAP-02 (DynamoDB)

| Direction | Artifact |
|-----------|----------|
| Control → Code | `terraform/kms.tf` — `aws_kms_key.phi`, `aws_kms_key.evidence` |
| Control → Code | `terraform/baseline.tf` — `aws_s3_bucket_server_side_encryption_configuration.uploads` |
| Control → Code | `terraform/main.tf` — `aws_dynamodb_table.intake` server_side_encryption block |
| Control → Code | `policies/sc1311_cmk_encryption.rego` — denies S3 buckets without KMS |
| Code → Control | All resources tagged `ControlRef = "SC.L2-3.13.11"` |

## SC.L2-3.13.8 — Transmission Confidentiality

**Gap closed:** GAP-03

| Direction | Artifact |
|-----------|----------|
| Control → Code | `terraform/baseline.tf` — `aws_s3_bucket_policy.uploads_tls` denying `aws:SecureTransport=false` |
| Control → Code | `policies/sc138_tls_required.rego` — denies S3 buckets without TLS policy |
| Code → Control | Policy metadata: `control_id: SC.L2-3.13.8` |

## MP.L2-3.8.9 — Media Sanitization

**Gap closed:** GAP-04

| Direction | Artifact |
|-----------|----------|
| Control → Code | `terraform/baseline.tf` — `aws_s3_bucket_versioning.uploads` |
| Control → Code | `policies/mp389_versioning.rego` — denies S3 buckets without versioning |
| Code → Control | Policy metadata: `control_id: MP.L2-3.8.9` |

## AC.L2-3.1.5 — Least Privilege

**Gap closed:** GAP-07

| Direction | Artifact |
|-----------|----------|
| Control → Code | `terraform/baseline.tf` — `aws_iam_role_policy.lambda_least_privilege` |
| Control → Code | `policies/ac315_least_privilege.rego` — denies wildcard IAM actions |
| Code → Control | Policy metadata: `control_id: AC.L2-3.1.5` |

## AU.L2-3.3.1 — Audit Logging

**Gap closed:** GAP-08

| Direction | Artifact |
|-----------|----------|
| Control → Code | `terraform/cloudtrail.tf` — `aws_cloudtrail.mgmt` multi-region, log file validation |
| Control → Code | `policies/au331_audit_logging.rego` — denies missing or misconfigured CloudTrail |
| Code → Control | Resource tagged `ControlRef = "AU.L2-3.3.1"` |

## AU.L2-3.3.1 — Evidence Vault

| Direction | Artifact |
|-----------|----------|
| Control → Code | `terraform/evidence_vault.tf` — Object Lock S3 bucket with KMS encryption |
| Control → Code | `.github/workflows/grc-gate.yml` — Step 4 signs and uploads evidence bundle |
| Control → Code | `scripts/verify-evidence.sh` — verifies SHA-256, Cosign signature, Object Lock retention |

## Gap Coverage Summary

| Gap | Control | Status | Layer |
|-----|---------|--------|-------|
| GAP-01 | SC.L2-3.13.11 | ✅ Closed | Terraform + Policy |
| GAP-02 | SC.L2-3.13.11 | ✅ Closed | Terraform |
| GAP-03 | SC.L2-3.13.8 | ✅ Closed | Terraform + Policy |
| GAP-04 | MP.L2-3.8.9 | ✅ Closed | Terraform + Policy |
| GAP-05 | SC.L2-3.13.1 | ⚠️ Partial | Terraform (SG created, vpc_config pending) |
| GAP-06 | SI.L2-3.14.6 | ❌ Open | Not implemented |
| GAP-07 | AC.L2-3.1.5 | ✅ Closed | Terraform + Policy |
| GAP-08 | AU.L2-3.3.1 | ✅ Closed | Terraform + Policy |