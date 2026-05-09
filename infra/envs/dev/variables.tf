variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name; used as a tag and as a prefix for resource names"
  type        = string
  default     = "zillow-baltimore"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
