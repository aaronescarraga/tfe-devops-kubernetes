#!/usr/bin/env bash
# ============================================================
# Personalizacion del proyecto para el entorno del cliente.
# Reemplaza los marcadores con los datos reales del proyecto GCP.
# Uso: ./setup-cliente.sh <PROJECT_ID> <DOCKER_USERNAME>
# ============================================================
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Uso: ./setup-cliente.sh <PROJECT_ID_GCP> <DOCKER_USERNAME>"
  echo "Ejemplo: ./setup-cliente.sh aaron-tfe-devops aarondocker"
  exit 1
fi

PROJECT_ID="$1"
DOCKER_USER="$2"
TFSTATE_BUCKET="${PROJECT_ID}-tfstate"
VELERO_BUCKET="tfe-devops-velero-backups-${PROJECT_ID}"

echo ">> Personalizando el proyecto para: ${PROJECT_ID}"

# 1. Backend de Terraform (bucket del state)
sed -i "s|BUCKET_TFSTATE_DEL_CLIENTE|${TFSTATE_BUCKET}|g" terraform/main.tf

# 2. Configuracion de Velero
sed -i "s|PROJECT_ID_DEL_CLIENTE|${PROJECT_ID}|g" kubernetes/velero/values-gcp.yaml

# 3. terraform.tfvars a partir del ejemplo
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
sed -i "s|tu-project-id-aqui|${PROJECT_ID}|g" terraform/terraform.tfvars

echo ">> Listo. Configurado con:"
echo "   - Project ID:      ${PROJECT_ID}"
echo "   - Bucket tfstate:  ${TFSTATE_BUCKET}"
echo "   - Bucket Velero:   ${VELERO_BUCKET}"
echo "   - Docker user:     ${DOCKER_USER} (configurar como secret DOCKER_USERNAME en GitHub)"
echo ""
echo ">> IMPORTANTE: crear el bucket del tfstate ANTES del primer 'terraform init':"
echo "   gsutil mb -p ${PROJECT_ID} -l us-central1 gs://${TFSTATE_BUCKET}"
echo "   gsutil versioning set on gs://${TFSTATE_BUCKET}"
