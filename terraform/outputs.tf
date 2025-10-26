output "cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_id
}

output "kubeconfig" {
  description = "Kubeconfig content (sensitive) - write to a file locally to use kubectl"
  value       = module.eks.kubeconfig
  sensitive   = true
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app_repo.repository_url
}
