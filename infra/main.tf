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

provider "kubernetes" {
  host                   = aws_eks_cluster.trivy_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.trivy_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.trivy_cluster.token
}

resource "kubernetes_deployment" "trivy_server" {
  metadata {
    name      = "trivy-server-tf"
    namespace = "default"
    labels = {
      app = "trivy-server-tf"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "trivy-server-tf"
      }
    }

    template {
      metadata {
        labels = {
          app = "trivy-server-tf"
        }
      }

      spec {
        container {
          name  = "trivy-server"
          image = "aquasec/trivy:latest"

          command = [
            "trivy",
            "server",
            "--listen",
            "0.0.0.0:10000"
          ]

          port {
            container_port = 10000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "trivy_service" {
  metadata {
    name      = "trivy-server-tf"
    namespace = "default"
  }

  spec {
    selector = {
      app = "trivy-server-tf"
    }

    port {
      port        = 10000
      target_port = 10000
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}
