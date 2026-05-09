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
