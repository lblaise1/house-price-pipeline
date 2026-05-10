# Dev environment composition.
# Wire modules here; do not put resource blocks directly in this file.

module "smoke_test" {
  source = "../../modules/ssm_smoke_test"

  project     = var.project
  environment = var.environment
  value       = "deployed-from-${var.environment}"
}

output "smoke_test_parameter_name" {
  description = "Name of the smoke-test SSM parameter"
  value       = module.smoke_test.parameter_name
}

# ============================================================
# Data lake (Step 4)
# ============================================================

module "data_lake" {
  source = "../../modules/data_lake"

  bucket_name = "zillow-baltimore-data-lake-${data.aws_caller_identity.current.account_id}"
}

output "data_lake_bucket_id" {
  description = "Data lake bucket name"
  value       = module.data_lake.bucket_id
}

output "data_lake_bucket_arn" {
  description = "Data lake bucket ARN"
  value       = module.data_lake.bucket_arn
}
