# Bucket principal para almacenar los backups de Velero
resource "google_storage_bucket" "velero_backups" {
  name          = "${var.backup_bucket_name}-${var.project_id}"
  location      = var.region
  project       = var.project_id
  force_destroy = true

  # Versionado para proteger contra borrados accidentales
  versioning {
    enabled = true
  }

  # Politica de ciclo de vida: eliminar backups antiguos automaticamente
  lifecycle_rule {
    condition {
      age = 30 # dias
    }
    action {
      type = "Delete"
    }
  }

  # Regla adicional: mover backups a almacenamiento frio despues de 7 dias
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Cifrado con clave gestionada por Google
  #encryption {
    #default_kms_key_name = null # Usar cifrado por defecto de Google
  #}

  # Etiquetas para identificacion y facturacion
  labels = {
    project     = "tfe-devops"
    environment = var.environment
    purpose     = "velero-backups"
  }

  # Prevenir acceso publico
  public_access_prevention = "enforced"

  uniform_bucket_level_access = true
}

# Bucket secundario para artefactos de CI/CD (imagenes, logs)
resource "google_storage_bucket" "artifacts" {
  name          = "tfe-devops-artifacts-${var.project_id}"
  location      = var.region
  project       = var.project_id
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    project     = "tfe-devops"
    environment = var.environment
    purpose     = "ci-cd-artifacts"
  }

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}
