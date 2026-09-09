variable "aws_region" {
  description = "AWS region used to deploy the Customer Feedback System"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name used for AWS resource tags"
  type        = string
  default     = "Allan Feedback System"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
