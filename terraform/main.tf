########################################
# Provider Configuration
########################################
provider "aws" {
  region = var.region
}

########################################
# Create ECR Repository
########################################
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

########################################
# Data Source for Availability Zones
########################################
data "aws_availability_zones" "available" {}

########################################
# VPC Module (AWS Provider v5 Compatible)
########################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1" # ✅ Compatible with AWS Provider 5.x

  name = "demo-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = length(var.private_subnets) > 0 ? var.private_subnets : ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = length(var.public_subnets) > 0 ? var.public_subnets : ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  tags = {
    Name = "demo-vpc"
  }
}

########################################
# EKS Module (AWS Provider v5 Compatible)
########################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5" # ✅ Compatible with AWS Provider 5.x

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    demo_nodes = {
      desired_size   = var.desired_capacity
      max_size       = var.max_capacity
      min_size       = var.min_capacity
      instance_types = [var.node_instance_type]
    }
  }

  tags = {
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}

