variable "project_id" {
  description = "ID del proyecto en Google Cloud Platform"
  type        = string
}

variable "region" {
  description = "Region de GCP donde se desplegara la infraestructura"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona dentro de la region"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Nombre del cluster GKE"
  type        = string
  default     = "tfe-devops-cluster"
}

variable "node_count" {
  description = "Numero de nodos por zona en el cluster"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Tipo de maquina para los nodos del cluster"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Tamano del disco de cada nodo en GB"
  type        = number
  default     = 50
}

variable "kubernetes_version" {
  description = "Version de Kubernetes para el cluster GKE"
  type        = string
  default     = "latest"
}

variable "backup_bucket_name" {
  description = "Nombre del bucket GCS para almacenar los backups de Velero"
  type        = string
  default     = "tfe-devops-velero-backups"
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "network_name" {
  description = "Nombre de la red VPC"
  type        = string
  default     = "tfe-devops-vpc"
}

variable "subnet_name" {
  description = "Nombre de la subred principal"
  type        = string
  default     = "tfe-devops-subnet"
}

variable "subnet_cidr" {
  description = "CIDR de la subred principal"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pods_cidr" {
  description = "CIDR para los pods de Kubernetes"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "CIDR para los servicios de Kubernetes"
  type        = string
  default     = "10.2.0.0/16"
}

variable "github_repository" {
  description = "Repositorio de GitHub autorizado para el pipeline (formato: usuario/repo)"
  type        = string
}