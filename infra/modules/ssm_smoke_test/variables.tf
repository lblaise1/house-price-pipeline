variable "project" {
  description = "Project name, used as a path prefix for the parameter"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
}

variable "value" {
  description = "The string value to store in the parameter"
  type        = string
  default     = "hello-from-terraform"
}
