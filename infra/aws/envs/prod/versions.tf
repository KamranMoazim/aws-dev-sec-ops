terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    key = "envs/prod/terraform.tfstate"
  }
}

provider "aws" {
  region = var.region

  dynamic "assume_role" {
    for_each = var.deploy_role_arn == null ? [] : [var.deploy_role_arn]

    content {
      role_arn     = assume_role.value
      session_name = "terraform-prod"
    }
  }

  default_tags {
    tags = {
      Project     = var.project
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# Route 53 records live in the shared account's zone; null dns_role_arn uses the caller (single-account mode).
provider "aws" {
  alias  = "dns"
  region = var.region

  dynamic "assume_role" {
    for_each = var.dns_role_arn == null ? [] : [var.dns_role_arn]

    content {
      role_arn     = assume_role.value
      session_name = "terraform-prod-dns"
    }
  }

  default_tags {
    tags = {
      Project     = var.project
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
