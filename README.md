# TFE DevOps — Automatización de microservicios en Kubernetes con backup y DR

**Trabajo de Fin de Estudios — Máster en Desarrollo y Operaciones (DevOps)**  
**Universidad Internacional de La Rioja (UNIR)**  
**Estudiante:** Cristian Aaron Escarraga Jimenez

---

## Descripción del proyecto

Este repositorio contiene la implementación técnica del TFE del Máster en DevOps de la UNIR. El proyecto diseña e implementa una plataforma de despliegue automatizado para microservicios sobre Kubernetes (GKE), integrando desde su diseño estrategias de respaldo y recuperación ante desastres mediante Velero.

## Stack tecnológico

| Herramienta | Versión | Propósito |
|---|---|---|
| Google Kubernetes Engine | 1.28+ | Orquestación de contenedores |
| Terraform | >= 1.5.0 | Infraestructura como código |
| GitHub Actions | - | Pipeline CI/CD |
| Docker | 24+ | Contenedorización |
| Velero | 1.13 | Backup y disaster recovery |
| FastAPI | 0.111 | Microservicio Python |
| Prometheus + Grafana | - | Monitoreo |
| Helm | 3+ | Gestor de paquetes K8s |

---

## Estructura del repositorio

```
tfe-devops-kubernetes/
├── terraform/                  # Infraestructura como código (GCP)
│   ├── main.tf                 # Proveedor y APIs
│   ├── variables.tf            # Variables
│   ├── gke.tf                  # Cluster Kubernetes
│   ├── network.tf              # VPC y redes
│   ├── storage.tf              # Buckets GCS
│   ├── iam.tf                  # Service accounts
│   ├── outputs.tf              # Outputs
│   └── terraform.tfvars.example
├── microservices/
│   └── api-service/            # Microservicio Python (FastAPI)
│       ├── main.py
│       ├── requirements.txt
│       ├── Dockerfile
│       └── test_main.py
├── kubernetes/
│   ├── base/                   # Manifiestos Kubernetes
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   └── ingress.yaml
│   └── velero/                 # Configuración de backup
│       ├── backup-schedule.yaml
│       ├── backup-policy.yaml
│       └── restore.yaml
├── .github/
│   └── workflows/
│       └── ci-cd.yml           # Pipeline CI/CD
├── helm/                       # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       └── deployment.yaml
└── docs/                       # Documentación adicional
```

---

## Requisitos previos

- Cuenta en Google Cloud Platform con créditos activos
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3.0
- [Docker](https://docs.docker.com/get-docker/)
- Cuenta en [Docker Hub](https://hub.docker.com/)
- Cuenta en [GitHub](https://github.com/) con Actions habilitado

---

## Instrucciones de despliegue

### 1. Clonar el repositorio
```bash
git clone https://github.com/TU_USUARIO/tfe-devops-kubernetes.git
cd tfe-devops-kubernetes
```

### 2. Configurar variables de Terraform
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tu project_id de GCP
```

### 3. Autenticarse en GCP
```bash
gcloud auth application-default login
gcloud config set project TU_PROJECT_ID
```

### 4. Aprovisionar infraestructura
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 5. Configurar kubectl
```bash
# El comando exacto lo muestra terraform output
terraform output kubectl_config_command
```

### 6. Desplegar microservicio
```bash
kubectl apply -f kubernetes/base/
```

### 7. Instalar Velero
```bash
velero install \
  --provider gcp \
  --plugins velero/velero-plugin-for-gcp:v1.9.0 \
  --bucket $(terraform output -raw velero_bucket_name) \
  --backup-location-config serviceAccount=$(terraform output -raw velero_service_account_email)
```

### 8. Aplicar políticas de backup
```bash
kubectl apply -f kubernetes/velero/backup-schedule.yaml
```

---

## Secrets necesarios en GitHub Actions

Configurar en **Settings → Secrets and variables → Actions**:

| Secret | Descripción |
|---|---|
| `GCP_PROJECT_ID` | ID del proyecto de GCP |
| `GCP_SA_KEY` | JSON de la service account de CI/CD |
| `DOCKER_USERNAME` | Usuario de Docker Hub |
| `DOCKER_PASSWORD` | Password o token de Docker Hub |

---

## Líneas de investigación cubiertas

- **Línea 2:** Administración y Seguridad para la Nube
- **Línea 3:** Automatización del Ciclo de Vida de las Aplicaciones
- **Línea 4:** Despliegue Automatizado de Infraestructura

---

## Licencia

MIT License — Ver archivo LICENSE para más detalles.
