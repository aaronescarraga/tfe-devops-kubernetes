.PHONY: help tf-init tf-plan tf-apply tf-destroy \
        k8s-deploy k8s-delete k8s-status \
        docker-build docker-push \
        test lint backup-now restore-list

# Configuracion
PROJECT_ID ?= $(shell grep project_id terraform/terraform.tfvars 2>/dev/null | cut -d'"' -f2)
REGION     ?= us-central1
CLUSTER    ?= tfe-devops-cluster
NAMESPACE  ?= tfe-devops
IMAGE      ?= tfe-api-service
TAG        ?= latest

# ============================================================
help: ## Mostrar ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

# ============================================================
# TERRAFORM
# ============================================================
tf-init: ## Inicializar Terraform
	cd terraform && terraform init

tf-plan: ## Planificar cambios de infraestructura
	cd terraform && terraform plan

tf-apply: ## Aplicar infraestructura en GCP
	cd terraform && terraform apply

tf-destroy: ## CUIDADO: Destruir toda la infraestructura
	cd terraform && terraform destroy

tf-output: ## Ver outputs de Terraform
	cd terraform && terraform output

# ============================================================
# KUBERNETES
# ============================================================
k8s-deploy: ## Desplegar todos los manifiestos en Kubernetes
	kubectl apply -f kubernetes/base/

k8s-delete: ## Eliminar todos los recursos de Kubernetes
	kubectl delete -f kubernetes/base/

k8s-status: ## Ver estado de pods y servicios
	kubectl get pods,services,hpa -n $(NAMESPACE)

k8s-logs: ## Ver logs del api-service
	kubectl logs -f deployment/api-service -n $(NAMESPACE)

k8s-shell: ## Abrir shell en un pod del api-service
	kubectl exec -it deployment/api-service -n $(NAMESPACE) -- /bin/sh

# ============================================================
# DOCKER
# ============================================================
docker-build: ## Construir imagen Docker del api-service
	docker build -t $(IMAGE):$(TAG) microservices/api-service/

docker-push: ## Publicar imagen en Docker Hub
	docker push $(IMAGE):$(TAG)

docker-run: ## Correr el microservicio localmente
	docker run -p 8080:8080 $(IMAGE):$(TAG)

# ============================================================
# TESTS
# ============================================================
test: ## Ejecutar tests del microservicio
	cd microservices/api-service && pytest test_main.py -v

lint: ## Verificar calidad del codigo Python
	cd microservices/api-service && flake8 main.py --max-line-length=100

# ============================================================
# VELERO - BACKUP Y RESTORE
# ============================================================
backup-now: ## Crear backup manual inmediato
	velero backup create manual-backup-$(shell date +%Y%m%d%H%M) \
		--include-namespaces $(NAMESPACE) --wait

backup-list: ## Listar todos los backups disponibles
	velero backup get

restore-list: ## Listar restauraciones disponibles
	velero restore get

backup-schedule: ## Aplicar schedules de backup programados
	kubectl apply -f kubernetes/velero/backup-schedule.yaml

# ============================================================
# KUBECTL CONFIG
# ============================================================
get-credentials: ## Configurar kubectl con el cluster GKE
	gcloud container clusters get-credentials $(CLUSTER) \
		--region $(REGION) --project $(PROJECT_ID)
