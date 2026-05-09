terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Every resource Terraform creates gets these tags automatically.
  # The "Project" tag matches the prefix our scoped IAM role allows.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "lblaise1/house-price-pipeline"
    }
  }
}
