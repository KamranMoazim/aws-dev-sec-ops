terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    key = "envs/shared/terraform.tfstate"
  }
}

provider "aws" {
  region = var.region

  dynamic "assume_role" {
    for_each = var.deploy_role_arn == null ? [] : [var.deploy_role_arn]

    content {
      role_arn     = assume_role.value
      session_name = "terraform-shared"
    }
  }

  default_tags {
    tags = {
      Project     = var.project
      Environment = "shared"
      ManagedBy   = "terraform"
    }
  }
}
