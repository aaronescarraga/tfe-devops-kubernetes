output "cluster_name" {
  description = "Nombre del cluster GKE creado"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint del API server de Kubernetes"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Certificado CA del cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Region donde esta desplegado el cluster"
  value       = google_container_cluster.primary.location
}

output "velero_bucket_name" {
  description = "Nombre del bucket GCS para los backups de Velero"
  value       = google_storage_bucket.velero_backups.name
}

output "velero_service_account_email" {
  description = "Email de la service account de Velero"
  value       = google_service_account.velero.email
}

output "cicd_service_account_email" {
  description = "Email de la service account del pipeline CI/CD"
  value       = google_service_account.cicd.email
}

output "network_name" {
  description = "Nombre de la red VPC creada"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Nombre de la subred principal"
  value       = google_compute_subnetwork.subnet.name
}

output "kubectl_config_command" {
  description = "Comando para configurar kubectl con el cluster creado"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}
