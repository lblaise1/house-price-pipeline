# A no-cost smoke-test resource used to validate the Terraform pipeline.
# AWS Systems Manager Parameter Store is free for "Standard" parameters.

resource "aws_ssm_parameter" "smoke" {
  name        = "/${var.project}/${var.environment}/smoke-test"
  description = "Smoke-test parameter created by Terraform to validate the deployment pipeline"
  type        = "String"
  value       = var.value
  tier        = "Standard"
}
