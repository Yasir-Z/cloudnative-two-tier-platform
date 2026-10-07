variable "aws_region" {
  type        = string
  description = "defines aws region"
  default     = "us-east-1"
}

variable "cidr_block" {
  type        = string
  description = "Defins cidr block"
  default     = "10.0.0.0/16"
}

variable "AZ_A" {
  type        = string
  description = "Defines availability zone A"
  default     = "us-east-1a"
}

variable "AZ_B" {
  type        = string
  description = "Defines availability zone B"
  default     = "us-east-1b"
}

variable "db_password" {
  type        = string
  description = "Defines password"
  default     = "admin123"
}
