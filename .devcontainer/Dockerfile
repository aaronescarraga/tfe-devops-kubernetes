FROM mcr.microsoft.com/devcontainers/python:3.11

ARG TERRAFORM_VERSION=1.9.8
ARG KUBECTL_VERSION=1.30.5
ARG HELM_VERSION=3.16.2
ARG VELERO_VERSION=1.14.1

# Dependencias base
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    gnupg \
    lsb-release \
    apt-transport-https \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Terraform
RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip \
    && chmod +x /usr/local/bin/terraform

# kubectl
RUN curl -fsSL "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

# Helm
RUN curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" -o /tmp/helm.tar.gz \
    && tar -xzf /tmp/helm.tar.gz -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && rm -rf /tmp/helm.tar.gz /tmp/linux-amd64 \
    && chmod +x /usr/local/bin/helm

# Velero CLI
RUN curl -fsSL "https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz" -o /tmp/velero.tar.gz \
    && tar -xzf /tmp/velero.tar.gz -C /tmp \
    && mv /tmp/velero-v${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/velero \
    && rm -rf /tmp/velero.tar.gz /tmp/velero-v${VELERO_VERSION}-linux-amd64 \
    && chmod +x /usr/local/bin/velero

# Google Cloud CLI
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update && apt-get install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Dependencias Python del microservicio (instaladas globalmente para que pytest funcione sin venv)
RUN pip install --no-cache-dir fastapi uvicorn pytest httpx pydantic flake8

ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True
