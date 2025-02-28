locals {

  alarm_severity_4xx_caps = upper(var.alarm_severity_4xx)
  alarm_severity_5xx_caps = upper(var.alarm_severity_5xx)
  bucket_400_error_alarm_severity = contains(["CRITICAL", "WARN", "INFO"], local.alarm_severity_4xx_caps) ? local.alarm_severity_4xx_caps : "WARN"
  bucket_500_error_alarm_severity = contains(["CRITICAL", "WARN", "INFO"], local.alarm_severity_5xx_caps) ? local.alarm_severity_5xx_caps : "WARN"
  # This is a really hacky work-around to generate replication and logging configs based on a boolean
  crr_is_enabled                         = var.enable_crr
  expire_non_current_versions_is_enabled = [var.enable_expire_non_current_versions]
  expire_current_versions_is_enabled     = [var.enable_expire_current_versions]
  logging_is_enabled                     = var.enable_logging

  name    = "s3"
  version = chomp(file("${path.module}/module.version"))

  account_alias_sections = split("-", data.aws_iam_account_alias.current.account_alias)

  # Parse the suffix of the current account alias to determine
  # which SDLC environment this is running in
  # (SDBX, DEV, TEST, PROD)
  environment = lower(local.account_alias_sections[length(local.account_alias_sections) - 1])
  alarm_env   = var.alarm_env == "" ? local.environment : var.alarm_env

  is_prod = local.environment == "prod" ? true : false

}

terraform {
  required_version = ">= 0.15"
}
