terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.38"
    }
  }
  
  backend "s3" {
    bucket         = "canary-case1-terraform-backend"
    key            = "canary-case1"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "canary-case1-terraform-backend-lock"
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "canary" {
  source = "../../terraform_modul"

  name_prefix = "case1" # Descriptive name for use case

  canary_runtime = "syn-nodejs-puppeteer-3.6"
  canary_source  = "canary.js"

  # Mandatory Tags for Rackspace Platform
  tags = {
    Application = "Canary"
    UseCase     = "Case1"
  }

  canary_vpc_config = {
    vpc_id = "vpc-123"
    subnet_ids = ["subnet-123", "subnet-124"]
    canary_aws_api_cidr = "0.0.0.0/0"
  }

  webhook_secret_arn = "arn:aws:secretsmanager:eu-central-1:<acc_id>:secret:<name>"
  s3_bucket_name_requests = "case1"
  canary_runtime_timeout = 600
}
