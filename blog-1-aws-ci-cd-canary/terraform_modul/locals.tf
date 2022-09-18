data "aws_region" "current" {}
data "aws_caller_identity" "whoami" {}

locals {
  version_zipped = "${path.module}/VERSION"
  version_module = "${path.module}/../VERSION"
  version        = fileexists(local.version_zipped) ? chomp(file(local.version_zipped)) : chomp(file(local.version_module))

  tags = var.tags

  teams_notifier_log_group = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.whoami.account_id}:log-group:/aws/lambda/${var.name_prefix}-canary-notifications"

  default_notifier_bucket = "832967823042-synthetics-canary-notifier"
  default_notifier_key    = "synthetics-canary/lambda-${local.version}.zip"

  ctnfc_parts           = var.custom_teams_notifier_function_code != null ? split("/", var.custom_teams_notifier_function_code) : []
  teams_notifier_bucket = length(local.ctnfc_parts) > 0 ? local.ctnfc_parts[0] : local.default_notifier_bucket
  teams_notifier_key    = length(local.ctnfc_parts) > 0 ? join("/", [for part in local.ctnfc_parts : part if part != local.ctnfc_parts[0]]) : local.default_notifier_key
}
