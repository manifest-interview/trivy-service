provider "aws" {
  region = var.aws_region
}

data "aws_iam_role" "eks_cluster_role" {
  name = "AmazonEKSAutoClusterRole"
}

resource "aws_eks_cluster" "trivy_cluster" {
  name     = "trivy-cluster"
  role_arn = data.aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  tags = {
    project = "manifest"
  }
}

data "aws_eks_cluster_auth" "trivy_cluster" {
  name = aws_eks_cluster.trivy_cluster.name
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "manifest_sboms_s3" {
  bucket = "manifest-sboms-${data.aws_caller_identity.current.account_id}"
  tags = {
    project = "manifest"
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.trivy_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.trivy_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.trivy_cluster.token
  }
}

resource "helm_release" "trivy" {
  name        = "trivy"
  repository  = "https://aquasecurity.github.io/helm-charts/"
  chart       = "trivy"
  namespace   = "default"
  timeout     = 300
  atomic      = true

  set {
    name  = "server.mode"
    value = "true"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.statefulset.enabled"
    value = "false"
  }

  set {
    name  = "aggregator.enabled"
    value = "false"
  }

  set {
    name  = "server.service.sessionAffinity"
    value = "None"
  }
}
