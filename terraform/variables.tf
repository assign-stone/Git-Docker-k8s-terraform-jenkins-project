variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "demo-eks-cluster"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnets (optional)"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of private subnets (optional)"
  type        = list(string)
  default     = []
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "desired_capacity" {
  description = "Desired capacity for node group"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Max capacity for node group"
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "Min capacity for node group"
  type        = number
  default     = 1
}

variable "ecr_repository_name" {
  description = "Name for the ECR repository"
  type        = string
  default     = "flask-app-repo"
}
