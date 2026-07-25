"""
Tests unitarios e de integracion para el API Service
Se ejecutan automaticamente en el pipeline CI/CD
"""

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


class TestHealthEndpoints:
    """Tests para los endpoints de salud del servicio."""

    def test_health_check_returns_200(self):
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_check_status_is_healthy(self):
        response = client.get("/health")
        data = response.json()
        assert data["status"] == "healthy"

    def test_health_check_has_required_fields(self):
        response = client.get("/health")
        data = response.json()
        assert "status" in data
        assert "service" in data
        assert "version" in data
        assert "uptime_seconds" in data
        assert "timestamp" in data

    def test_readiness_probe_returns_200(self):
        response = client.get("/ready")
        assert response.status_code == 200

    def test_readiness_probe_status_ready(self):
        response = client.get("/ready")
        data = response.json()
        assert data["status"] == "ready"

    def test_info_endpoint_returns_200(self):
        response = client.get("/info")
        assert response.status_code == 200


class TestItemsEndpoints:
    """Tests para los endpoints CRUD de items."""

    def test_list_items_returns_200(self):
        response = client.get("/items")
        assert response.status_code == 200

    def test_list_items_returns_list(self):
        response = client.get("/items")
        data = response.json()
        assert isinstance(data, list)

    def test_list_items_has_initial_data(self):
        response = client.get("/items")
        data = response.json()
        assert len(data) > 0

    def test_get_item_by_id_returns_200(self):
        response = client.get("/items/1")
        assert response.status_code == 200

    def test_get_item_by_id_returns_correct_item(self):
        response = client.get("/items/1")
        data = response.json()
        assert data["id"] == 1
        assert "name" in data

    def test_get_nonexistent_item_returns_404(self):
        response = client.get("/items/99999")
        assert response.status_code == 404

    def test_create_item_returns_201(self):
        new_item = {"name": "Test Item", "description": "Item de prueba"}
        response = client.post("/items", json=new_item)
        assert response.status_code == 201

    def test_create_item_returns_created_data(self):
        new_item = {"name": "Nuevo Item", "description": "Descripcion de prueba"}
        response = client.post("/items", json=new_item)
        data = response.json()
        assert data["name"] == "Nuevo Item"
        assert data["id"] is not None
        assert data["active"] is True

    def test_delete_item_returns_204(self):
        # Crear un item para luego borrarlo
        new_item = {"name": "Item a Borrar", "description": "Se borrara"}
        create_response = client.post("/items", json=new_item)
        item_id = create_response.json()["id"]

        delete_response = client.delete(f"/items/{item_id}")
        assert delete_response.status_code == 204

    def test_delete_nonexistent_item_returns_404(self):
        response = client.delete("/items/99999")
        assert response.status_code == 404

    def test_deleted_item_not_in_list(self):
        # Crear item
        new_item = {"name": "Item Temporal", "description": "Temporal"}
        create_response = client.post("/items", json=new_item)
        item_id = create_response.json()["id"]

        # Borrar item
        client.delete(f"/items/{item_id}")

        # Verificar que ya no aparece en la lista
        list_response = client.get("/items")
        items = list_response.json()
        item_ids = [item["id"] for item in items]
        assert item_id not in item_ids


class TestRootEndpoint:
    """Tests para el endpoint raiz."""

    def test_root_returns_200(self):
        response = client.get("/")
        assert response.status_code == 200

    def test_root_has_message(self):
        response = client.get("/")
        data = response.json()
        assert "message" in data
        assert "docs" in data
