provider "aws" {
  region = var.region
}

# Create an ECR repository to host images
resource "aws_ecr_repository" "app_repo" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    ManagedBy = "terraform"
  }
}

# Use the official terraform-aws-eks module for production-level EKS
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = "demo-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = length(var.private_subnets) > 0 ? var.private_subnets : ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = length(var.public_subnets) > 0 ? var.public_subnets : ["10.0.101.0/24", "10.0.102.0/24"]
}

# Data source for AZs
data "aws_availability_zones" "available" {}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  subnets         = module.vpc.private_subnets

  node_groups = {
    demo_nodes = {
      desired_capacity = var.desired_capacity
      max_capacity     = var.max_capacity
      min_capacity     = var.min_capacity

      instance_types = [var.node_instance_type]
    }
  }

  tags = {
    Environment = "demo"
  }
}
