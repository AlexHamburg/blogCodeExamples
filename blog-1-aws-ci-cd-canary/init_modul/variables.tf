variable "bucket_name" {
  type        = string
  description = "A name applied to the S3 bucket created to ensure a unique name."
}

variable "dynamodb_table_name" {
  type        = string
  description = "A name applied to the Dynamo DB table."
}