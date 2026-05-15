# Monitoring and Detection
# CMMC SI.L2-3.14.6 - Security Alerts / Advisories / Directives
# CMMC AU.L2-3.3.1 - Audit and Accountability

######################################################################
# AWS Config recorder - continuous resource configuration monitoring
######################################################################

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

resource "aws_config_configuration_recorder" "main" {
  name     = "${local.name_prefix}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${local.name_prefix}-delivery"
  s3_bucket_name = aws_s3_bucket.trail.id
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

######################################################################
# AWS Config Rules - detect compliance drift
# CMMC SC.L2-3.13.11 - S3 must use KMS encryption
######################################################################

resource "aws_config_config_rule" "s3_kms_encryption" {
  name = "${local.name_prefix}-s3-kms-encryption"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  tags = {
    ControlRef = "SC.L2-3.13.11"
  }

  depends_on = [aws_config_configuration_recorder_status.main]
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

  depends_on = [aws_config_configuration_recorder_status.main]
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

  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "iam_no_wildcards" {
  name = "${local.name_prefix}-iam-no-inline-policy-wildcards"

  source {
    owner             = "AWS"
    source_identifier = "IAM_INLINE_POLICY_BLOCKED_KMS_ACTIONS"
  }

  tags = {
    ControlRef = "AC.L2-3.1.5"
  }

  depends_on = [aws_config_configuration_recorder_status.main]
}