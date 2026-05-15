# Monitoring and Detection
# CMMC SI.L2-3.14.6 - Security Alerts / Advisories / Directives
# CMMC AU.L2-3.3.1 - Audit and Accountability

resource "aws_iam_role" "config" {
  name = "${local.name_prefix}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    ControlRef = "AU.L2-3.3.1"
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_config_rule" "s3_kms_encryption" {
  name = "${local.name_prefix}-s3-kms-encryption"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  tags = {
    ControlRef = "SC.L2-3.13.11"
  }
}

resource "aws_config_config_rule" "s3_versioning" {
  name = "${local.name_prefix}-s3-versioning"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }

  tags = {
    ControlRef = "MP.L2-3.8.9"
  }
}

resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "${local.name_prefix}-cloudtrail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  tags = {
    ControlRef = "AU.L2-3.3.1"
  }
}

resource "aws_config_config_rule" "iam_least_privilege" {
  name = "${local.name_prefix}-iam-least-privilege"

  source {
    owner             = "AWS"
    source_identifier = "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS"
  }

  tags = {
    ControlRef = "AC.L2-3.1.5"
  }
}