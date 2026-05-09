# Remote state backend.
# Bucket and lock table were created manually in Phase B (one-time bootstrap)
# because Terraform cannot manage its own backend.
#
# To re-initialize after changing backend config:
#   terraform init -reconfigure

terraform {
  required_version = ">= 1.13.0"

  backend "s3" {
    bucket         = "zillow-baltimore-tf-state-923347312486"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "zillow-baltimore-tf-locks"
    encrypt        = true
  }
}
