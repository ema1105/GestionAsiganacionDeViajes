"""Pruebas del endpoint. Requiere haber ejecutado entrenar.py.

Ejecutar:  python -m pytest -q
"""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

# Garantizar que los tests pasen con o sin API key
os.environ.pop("GAV_API_KEY", None)

import pytest
from fastapi.testclient import TestClient

from app import app


@pytest.fixture(scope="module")
def cliente():
    with TestClient(app) as c:
        yield c


def test_un_mes(cliente):
    r = cliente.get("/api/prediccion/mensual", params={"anio": 2027, "mes": 10})
    assert r.status_code == 200
    d = r.json()
    assert set(d) == {"generado_en", "modelo", "periodo_objetivo", "periodo_base",
                      "comparacion", "otros_meses"}
    obj = d["periodo_objetivo"]
    assert obj["desde"] == obj["hasta"] == "2027-10"
    assert d["periodo_base"]["desde"] == "2026-10"
    assert obj["intervalo"]["min"] <= obj["solicitudes_predichas"] <= obj["intervalo"]["max"]
    assert d["comparacion"]["tendencia"] in {"incremento", "disminucion", "estable"}
    assert len(d["otros_meses"]) == 12


def test_rango_de_meses(cliente):
    r = cliente.get("/api/prediccion/mensual", params={"anio": 2027, "mes": 9, "mes_fin": 10})
    d = r.json()
    assert d["periodo_objetivo"]["etiqueta"] == "sep 2027 – oct 2027"
    marcados = [m["periodo"] for m in d["otros_meses"] if m["en_periodo"]]
    assert marcados == ["2027-09", "2027-10"]
    suma = sum(m["solicitudes_predichas"] for m in d["otros_meses"] if m["en_periodo"])
    assert abs(suma - d["periodo_objetivo"]["solicitudes_predichas"]) <= 2  # redondeo


def test_intervalo_por_mes(cliente):
    d = cliente.get("/api/prediccion/mensual", params={"anio": 2027, "mes": 1}).json()
    for m in d["otros_meses"]:
        if m["solicitudes_predichas"] is None:
            assert m["intervalo"] is None
        else:
            assert m["intervalo"]["min"] <= m["solicitudes_predichas"] <= m["intervalo"]["max"]


def test_rango_que_cruza_de_anio(cliente):
    d = cliente.get("/api/prediccion/mensual",
                    params={"anio": 2026, "mes": 11, "mes_fin": 2}).json()
    assert (d["periodo_objetivo"]["desde"], d["periodo_objetivo"]["hasta"]) == ("2026-11", "2027-02")
    assert (d["periodo_base"]["desde"], d["periodo_base"]["hasta"]) == ("2025-11", "2026-02")


def test_base_sin_datos(cliente):
    r = cliente.get("/api/prediccion/mensual", params={"anio": 2028, "mes": 12})
    assert r.status_code == 422  # dic 2027 aún no existe como dato real


def test_fuera_de_horizonte(cliente):
    r = cliente.get("/api/prediccion/mensual",
                    params={"anio": 2030, "mes": 1, "anio_base": 2025})
    assert r.status_code == 422


def test_parametros_invalidos(cliente):
    assert cliente.get("/api/prediccion/mensual", params={"anio": 2027, "mes": 13}).status_code == 422
    assert cliente.get("/api/prediccion/mensual",
                       params={"anio": 2027, "mes": 1, "anio_base": 2027}).status_code == 422


def test_info_modelo(cliente):
    d = cliente.get("/api/prediccion/modelo").json()
    assert d["metricas"]["mae"] > 0 and "arquitectura" in d


def test_salud(cliente):
    d = cliente.get("/api/prediccion/salud").json()
    assert d["estado"] == "ok"


def test_autenticacion_con_api_key(cliente):
    """Verifica que al definir GAV_API_KEY, las peticiones sin header reciban 401."""
    import config
    original = config.API_KEY
    try:
        config.API_KEY = "clave-secreta-test"
        # Sin header → 401
        r = cliente.get("/api/prediccion/mensual", params={"anio": 2027, "mes": 10})
        assert r.status_code == 401
        # Con header correcto → 200
        r = cliente.get("/api/prediccion/mensual", params={"anio": 2027, "mes": 10},
                        headers={"Authorization": "Bearer clave-secreta-test"})
        assert r.status_code == 200
        # /salud sigue abierto siempre
        r = cliente.get("/api/prediccion/salud")
        assert r.status_code == 200
    finally:
        config.API_KEY = original
