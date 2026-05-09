output "parameter_arn" {
  description = "ARN of the SSM parameter"
  value       = aws_ssm_parameter.smoke.arn
}

output "parameter_name" {
  description = "Full name of the SSM parameter"
  value       = aws_ssm_parameter.smoke.name
}
