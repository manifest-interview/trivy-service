variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket to store SBOMs."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to be used for the EKS cluster."
  type        = list(string)
}
