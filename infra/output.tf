output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.trivy_cluster.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster."
  value       = aws_eks_cluster.trivy_cluster.endpoint
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket for SBOMs."
  value       = aws_s3_bucket.manifest_sboms_s3.arn
}
