# MANDATORY
variable "name_prefix" { 
  type        = string
  description = "prefix for all resource names created in this module"
  validation {
    condition     = length(var.name_prefix) <= 21
    error_message = "Name prefix must not exceed 21 characters."
  }
}
# MANDATORY
variable "tags" {
  type        = map(string)
  description = "map of tags to apply to all resources"
}
# MANDATORY
variable "canary_runtime" {
  type        = string
  description = "used runtime of canary lambda"
  validation {
    condition     = contains(["syn-nodejs-puppeteer-3.1", "syn-nodejs-puppeteer-3.0", "syn-python-selenium-1.0", "syn-nodejs-puppeteer-3.6"], var.canary_runtime)
    error_message = "Unsupported canary runtime found."
  }
}
# MANDATORY
variable "canary_source" {
  type        = string
  description = "source-code file for canary lambda"
}
# MANDATORY
variable "s3_bucket_name_requests" {
  type        = string
  description = "s3 bucket name with requests bodys"
}


# OPTIONAL
variable "stage" {
  type        = string
  default     = 90
  description = "current stage"
}
# OPTIONAL
variable "logs_retention_days" {
  type        = number
  default     = 3
  description = "days to store logs"
}
# OPTIONAL
variable "canary_handler" {
  type        = string
  default     = "canary.handler"
  description = "name of the handler function of the canary lamdba"
}
# OPTIONAL
variable "canary_schedule" {
  type        = number
  default     = "60" //in min
  description = "rate of the canary lamdba schedule in minutes"
}
# OPTIONAL
variable "canary_runtime_timeout" {
  type        = number
  default     = 60 // in sec
  description = "time in seconds the lambda is allowed to run before forcefully shutdown"
}
# OPTIONAL
variable "canary_memory" {
  type        = number
  default     = 960 // in mb
  description = "memory in mb for the lambda function"
  validation {
    condition     = var.canary_memory >= 960 && var.canary_memory % 64 == 0
    error_message = "Canary function memory must be at least 960 and dividable by 64."
  }
}
# OPTIONAL
variable "canary_tracing" {
  type        = bool
  default     = false
  description = "wether to use active tracing with x-ray"
}
# OPTIONAL
variable "canary_retention_days" {
  type = object({
    failure = number,
  success = number })
  default     = { failure = 7, success = 3 }
  description = "Number in days how long to store canary results for successful and failed runs."
}
# OPTIONAL
variable "canary_vpc_config" {
  type = object({
    vpc_id              = string,
    subnet_ids          = list(string),
    canary_aws_api_cidr = string
  })
  default     = null
  description = "Custom canary VPC configuration. Enables monitoring of internal applications."
}
# OPTIONAL
variable "alarm_threshold_time" {
  type        = number
  default     = 60
  description = "Time in minutes which the the canary which fail consecutively until alarm goes off"
}
# OPTIONAL
variable "webhook_is_given" {
  type        = string
  description = "bs"
  default     = false
}
# OPTIONAL
variable "webhook_secret_arn" {
  type        = string
  description = "The ARN of the AWS secrets holding the value of the key 'teams_webhook_url'"
  default     = null
}
# OPTIONAL
variable "custom_teams_notifier_function_code" {
  type        = string
  description = "S3 location of custom team notifier function code. Must be full path incl. bucket name"
  default     = null
}
# OPTIONAL
variable "kms_key_deletion_schedule" {
  type        = number
  description = "number in days until kms key for canary resources is deleted"
  default     = 7
}
# OPTIONAL
variable "force_destroy" {
  type        = bool
  description = "destroy an S3 bucket even if non-empty ?"
  default     = true
}
