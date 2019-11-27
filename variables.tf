variable "aws_key_name" {
  description = "EC2 Region for the VPC"
  type        = string
  default     = "aws-keypair"
}

variable "aws_region" {
  description = "EC2 Region for the VPC"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Tags"
  type        = map
}
