"""
TFE DevOps UNIR - API Service
Microservicio de ejemplo construido con FastAPI
Demuestra la plataforma de despliegue automatizado en Kubernetes
"""

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
import json
import logging
import time
from datetime import datetime

# Configuracion de logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Inicializacion de la aplicacion
app = FastAPI(
    title="TFE DevOps API Service",
    description="Microservicio de ejemplo para el TFE del Master en DevOps - UNIR",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS para permitir acceso desde el frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Variables de entorno para configuracion
APP_NAME = os.getenv("APP_NAME", "tfe-api-service")
APP_ENV  = os.getenv("APP_ENV", "development")
VERSION  = os.getenv("APP_VERSION", "1.0.0")

# Ruta del archivo de persistencia.
# En Kubernetes, DATA_FILE (via ConfigMap) apunta a /data/items.json,
# montado sobre el PersistentVolumeClaim api-service-data.
# En local/tests, por defecto usa una ruta relativa para no requerir el PVC.
DATA_FILE = os.getenv("DATA_FILE", "data/items.json")

# Tiempo de inicio para calcular uptime
START_TIME = time.time()

# ============================================================
# MODELOS DE DATOS
# ============================================================

class Item(BaseModel):
    id: Optional[int] = None
    name: str
    description: Optional[str] = None
    active: bool = True
    created_at: Optional[str] = None

class ItemCreate(BaseModel):
    name: str
    description: Optional[str] = None

class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    environment: str
    uptime_seconds: float
    timestamp: str

class InfoResponse(BaseModel):
    service: str
    version: str
    environment: str
    kubernetes_node: str
    kubernetes_pod: str

# ============================================================
# PERSISTENCIA EN DISCO (PersistentVolumeClaim)
# ============================================================
# Sustituye el almacenamiento en memoria (items_db como lista Python)
# por un archivo JSON en disco. En produccion, DATA_FILE vive en el
# PVC api-service-data (ReadWriteOnce), por lo que el Deployment se
# fija a 1 replica (ver hpa.yaml: minReplicas=maxReplicas=1) mientras
# el microservicio use este patron de escritor unico.

DEFAULT_SEED = [
    {"id": 1, "name": "Kubernetes", "description": "Orquestador de contenedores", "active": True},
    {"id": 2, "name": "Velero", "description": "Herramienta de backup para Kubernetes", "active": True},
    {"id": 3, "name": "Terraform", "description": "Infraestructura como codigo", "active": True},
    {"id": 4, "name": "GitHub Actions", "description": "Plataforma de CI/CD", "active": True},
    {"id": 5, "name": "Prometheus", "description": "Sistema de monitoreo y alertas", "active": True},
]


def _seed_items():
    now = datetime.now().isoformat()
    return [Item(created_at=now, **d) for d in DEFAULT_SEED]


def load_data():
    """Carga items_db y next_id desde DATA_FILE. Si no existe, crea el seed inicial."""
    directory = os.path.dirname(DATA_FILE)
    if directory:
        os.makedirs(directory, exist_ok=True)

    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, "r") as f:
                raw = json.load(f)
            items = [Item(**item) for item in raw.get("items", [])]
            next_id = raw.get("next_id", (max([i.id for i in items], default=0) + 1))
            logger.info(f"Datos cargados desde {DATA_FILE} ({len(items)} items)")
            return items, next_id
        except (json.JSONDecodeError, OSError) as e:
            logger.warning(f"No se pudo leer {DATA_FILE} ({e}), usando datos semilla")

    items = _seed_items()
    next_id = len(items) + 1
    save_data(items, next_id)
    logger.info(f"Archivo {DATA_FILE} no existia, creado con datos semilla")
    return items, next_id


def save_data(items: List[Item], next_id: int):
    """Persiste items_db y next_id en DATA_FILE."""
    payload = {
        "items": [item.model_dump() for item in items],
        "next_id": next_id,
    }
    try:
        with open(DATA_FILE, "w") as f:
            json.dump(payload, f, indent=2, default=str)
    except OSError as e:
        logger.error(f"No se pudo escribir en {DATA_FILE}: {e}")


items_db, next_id = load_data()

# ============================================================
# ENDPOINTS DE SALUD Y ESTADO
# ============================================================

@app.get(
    "/health",
    response_model=HealthResponse,
    tags=["Health"],
    summary="Verificar estado del servicio"
)
async def health_check():
    """
    Endpoint de health check utilizado por Kubernetes para liveness y readiness probes.
    Devuelve el estado actual del servicio y su tiempo de actividad.
    """
    uptime = time.time() - START_TIME
    return HealthResponse(
        status="healthy",
        service=APP_NAME,
        version=VERSION,
        environment=APP_ENV,
        uptime_seconds=round(uptime, 2),
        timestamp=datetime.now().isoformat()
    )

@app.get(
    "/ready",
    tags=["Health"],
    summary="Readiness probe para Kubernetes"
)
async def readiness():
    """
    Readiness probe: indica si el servicio esta listo para recibir trafico.
    Kubernetes usa este endpoint antes de enrutar trafico al pod.
    """
    return {"status": "ready", "timestamp": datetime.now().isoformat()}

@app.get(
    "/info",
    response_model=InfoResponse,
    tags=["Info"],
    summary="Informacion del servicio y entorno"
)
async def info():
    """
    Devuelve informacion sobre el entorno de ejecucion, incluyendo
    el nodo y pod de Kubernetes donde esta corriendo el servicio.
    """
    return InfoResponse(
        service=APP_NAME,
        version=VERSION,
        environment=APP_ENV,
        kubernetes_node=os.getenv("NODE_NAME", "local"),
        kubernetes_pod=os.getenv("POD_NAME", "local")
    )

# ============================================================
# ENDPOINTS CRUD DE ITEMS
# ============================================================

@app.get(
    "/items",
    response_model=List[Item],
    tags=["Items"],
    summary="Listar todos los items"
)
async def list_items():
    """Retorna la lista completa de items activos."""
    logger.info(f"GET /items - Retornando {len(items_db)} items")
    return [item for item in items_db if item.active]

@app.get(
    "/items/{item_id}",
    response_model=Item,
    tags=["Items"],
    summary="Obtener un item por ID"
)
async def get_item(item_id: int):
    """Retorna un item especifico por su ID."""
    item = next((i for i in items_db if i.id == item_id and i.active), None)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item con ID {item_id} no encontrado"
        )
    logger.info(f"GET /items/{item_id} - Item encontrado: {item.name}")
    return item

@app.post(
    "/items",
    response_model=Item,
    status_code=status.HTTP_201_CREATED,
    tags=["Items"],
    summary="Crear un nuevo item"
)
async def create_item(item_data: ItemCreate):
    """Crea un nuevo item y lo persiste en disco."""
    global next_id
    new_item = Item(
        id=next_id,
        name=item_data.name,
        description=item_data.description,
        active=True,
        created_at=datetime.now().isoformat()
    )
    items_db.append(new_item)
    next_id += 1
    save_data(items_db, next_id)
    logger.info(f"POST /items - Item creado y persistido: {new_item.name} (ID: {new_item.id})")
    return new_item

@app.delete(
    "/items/{item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    tags=["Items"],
    summary="Eliminar un item"
)
async def delete_item(item_id: int):
    """Elimina (desactiva) un item por su ID y persiste el cambio en disco."""
    item = next((i for i in items_db if i.id == item_id and i.active), None)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item con ID {item_id} no encontrado"
        )
    item.active = False
    save_data(items_db, next_id)
    logger.info(f"DELETE /items/{item_id} - Item eliminado y persistido: {item.name}")

# ============================================================
# ENDPOINT RAIZ
# ============================================================

@app.get("/", tags=["Root"])
async def root():
    """Endpoint raiz del servicio."""
    return {
        "message": "TFE DevOps API Service - UNIR Master en DevOps",
        "docs": "/docs",
        "health": "/health",
        "version": VERSION
    }
