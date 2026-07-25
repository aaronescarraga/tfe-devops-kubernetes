resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  
  deletion_protection = false 

  # Usar node pool separado — buena practica recomendada por Google
  remove_default_node_pool = true
  initial_node_count       = 1

  # Fijar zona y tipo de disco para evitar problemas de stock/cuota en el pool temporal
  node_locations = ["us-central1-a"]

  node_config {
    disk_type = "pd-standard"
  }

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Configuracion de networking para pods y servicios
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Habilitar Workload Identity para acceso seguro a GCP desde pods
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Deshabilitar cliente HTTP legacy para mayor seguridad
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Habilitar addons utiles
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Logging y monitoring integrados con Google Cloud
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Mantenimiento en horario de baja actividad
  maintenance_policy {
    recurring_window {
      start_time = "2024-01-01T03:00:00Z"
      end_time   = "2024-01-01T07:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  depends_on = [
    google_project_service.apis,
    google_compute_network.vpc,
    google_compute_subnetwork.subnet,
  ]

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

# Node pool principal del cluster
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  node_locations = ["us-central1-a"] 

  # Actualizacion automatica con surge para minimizar downtime
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  # Reparacion automatica de nodos
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"

    # Service account con privilegios minimos
    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity en los nodos
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Etiquetas para identificar los nodos
    labels = {
      env     = var.environment
      project = "tfe-devops"
    }

    tags = ["gke-node", var.cluster_name]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
