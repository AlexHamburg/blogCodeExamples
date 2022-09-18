terraform {
  required_version = ">= 0.13.0"
}

provider "aws" {
  region = "eu-central-1"
}

module "tf_backend" {
  source = "../../init_modul"

  bucket_name        = "canary-case1-terraform-backend"
  dynamodb_table_name = "canary-case1-terraform-backend-lock"
}
