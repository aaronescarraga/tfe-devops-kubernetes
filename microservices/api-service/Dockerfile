# ============================================================
# Stage 1: Builder — instala dependencias
# ============================================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Instalar dependencias del sistema necesarias
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copiar y instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir --prefix=/install -r requirements.txt

# ============================================================
# Stage 2: Runtime — imagen final liviana
# ============================================================
FROM python:3.11-slim AS runtime

# Metadatos de la imagen
LABEL maintainer="TFE DevOps UNIR"
LABEL version="1.0.0"
LABEL description="API Service - TFE Master DevOps UNIR"

# Usuario no root por seguridad
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copiar dependencias instaladas del builder
COPY --from=builder /install /usr/local

# Copiar codigo fuente
COPY --chown=appuser:appuser . .

# Variables de entorno por defecto
ENV APP_NAME=tfe-api-service \
    APP_ENV=production \
    APP_VERSION=1.0.0 \
    PORT=8080

# Cambiar al usuario no root
USER appuser

# Exponer el puerto
EXPOSE 8080

# Health check interno del contenedor
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

# Comando de inicio
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "2"]
