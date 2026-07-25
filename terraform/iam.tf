# Service Account para los nodos del cluster GKE
resource "google_service_account" "gke_nodes" {
  account_id   = "tfe-devops-gke-nodes"
  display_name = "TFE DevOps GKE Node Service Account"
  project      = var.project_id
}

# Permisos minimos necesarios para los nodos del cluster
resource "google_project_iam_member" "gke_nodes_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer",
    "roles/artifactregistry.reader",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"

  depends_on = [google_project_service.apis]
}

# Service Account especifico para Velero (backup y restore)
resource "google_service_account" "velero" {
  account_id   = "tfe-devops-velero"
  display_name = "TFE DevOps Velero Backup Service Account"
  project      = var.project_id
}

# Permisos de Velero sobre el bucket de backups
resource "google_storage_bucket_iam_member" "velero_bucket_admin" {
  bucket = google_storage_bucket.velero_backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.velero.email}"
}

resource "google_storage_bucket_iam_member" "velero_bucket_viewer" {
  bucket = google_storage_bucket.velero_backups.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.velero.email}"
}

# Workload Identity: permite a Velero (pod en K8s) usar la SA de GCP sin claves
resource "google_service_account_iam_member" "velero_workload_identity" {
  service_account_id = google_service_account.velero.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[velero/velero]"

  depends_on = [google_container_cluster.primary]
}

# Service Account para el pipeline CI/CD (GitHub Actions)
resource "google_service_account" "cicd" {
  account_id   = "tfe-devops-cicd"
  display_name = "TFE DevOps CI/CD Pipeline Service Account"
  project      = var.project_id
}

# Permisos del pipeline CI/CD para desplegar en GKE
resource "google_project_iam_member" "cicd_roles" {
  for_each = toset([
    "roles/container.developer",         # Desplegar en GKE
    "roles/storage.objectAdmin",         # Subir artefactos
    "roles/artifactregistry.writer",     # Publicar imagenes Docker
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cicd.email}"

  depends_on = [google_project_service.apis]
}

