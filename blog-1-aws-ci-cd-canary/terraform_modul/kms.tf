resource "aws_kms_key" "canary" {
  description             = "Used by ${var.name_prefix} syntatic canary"
  deletion_window_in_days = var.kms_key_deletion_schedule
  policy                  = data.aws_iam_policy_document.canary_kms_key.json

  tags = local.tags
}

resource "aws_kms_alias" "canary" {
  name          = "alias/${var.name_prefix}-canary"
  target_key_id = aws_kms_key.canary.key_id
}

data "aws_iam_policy_document" "canary_kms_key" {
  policy_id = "CanaryResourcesCMKPolicy"

  statement {
    sid       = "GrantAccessToOwner"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      identifiers = [data.aws_caller_identity.whoami.account_id]
      type        = "AWS"
    }
  }

  statement {
    sid    = "AllowCanaryRolesToWorkWithKey"
    effect = "Allow"
    principals {
      identifiers = [aws_iam_role.canary.arn, aws_iam_role.team_notifications_function.arn]
      type        = "AWS"
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
      "kms:CreateGrant"
    ]
    resources = ["*"]
  }
}
