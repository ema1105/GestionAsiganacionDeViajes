"""API del prediction-service de GAV (FastAPI).

Ejecutar:  uvicorn app:app --host 0.0.0.0 --port 8000
Docs interactivas: http://localhost:8000/docs
"""
from __future__ import annotations

import contextlib
import io
import json
import logging
import shutil
import threading
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

import config
from src.pronostico import ErrorPeticion, Predictor

logger = logging.getLogger("prediction-service")

estado: dict = {}

# ─────────────────────────────────── Autenticación opcional por API key ──

seguridad = HTTPBearer(auto_error=False)


async def verificar_api_key(
    credenciales: HTTPAuthorizationCredentials | None = Depends(seguridad),
) -> None:
    """Si GAV_API_KEY está definida, exige Authorization: Bearer <clave>.
    Si no está definida, deja pasar todo (modo abierto para desarrollo)."""
    if config.API_KEY is None:
        return  # sin clave configurada → abierto
    if credenciales is None or credenciales.credentials != config.API_KEY:
        raise HTTPException(401, "API key inválida o ausente.")


# ─────────────────────────────────────────────────────── Ciclo de vida ──

@asynccontextmanager
async def ciclo_vida(_: FastAPI):
    estado["predictor"] = Predictor.desde_artefactos()
    yield
    estado.clear()


app = FastAPI(
    title="GAV · prediction-service",
    description="Predicción de solicitudes de viaje por periodo con redes neuronales artificiales.",
    version="1.0.0",
    lifespan=ciclo_vida,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


def predictor() -> Predictor:
    if "predictor" not in estado:
        raise HTTPException(503, "Modelo no cargado. Ejecute entrenar.py y reinicie el servicio.")
    return estado["predictor"]


# ────────────────────────────────────────────────────────── Endpoints ──

@app.get("/api/prediccion/mensual", summary="Predicción de solicitudes para un periodo",
         dependencies=[Depends(verificar_api_key)])
def prediccion_mensual(
    anio: int = Query(..., ge=2000, le=2100, description="Año del periodo a predecir"),
    mes: int = Query(..., ge=1, le=12, description="Mes de inicio del periodo"),
    mes_fin: int | None = Query(None, ge=1, le=12,
                                description="Mes de fin (opcional). Si es menor que `mes`, "
                                            "el periodo cruza al año siguiente."),
    anio_base: int | None = Query(None, ge=2000, le=2100,
                                  description="Año de comparación (por defecto anio - 1)"),
):
    if anio_base is not None and anio_base >= anio:
        raise HTTPException(422, "anio_base debe ser menor que anio.")
    try:
        return predictor().prediccion_mensual(anio, mes, mes_fin, anio_base)
    except ErrorPeticion as e:
        raise HTTPException(422, str(e)) from e


@app.get("/api/prediccion/modelo", summary="Ficha técnica y métricas del modelo",
         dependencies=[Depends(verificar_api_key)])
def info_modelo():
    p = predictor()
    return {**p.meta, "horizonte_disponible_hasta": str(max(p.pronosticos))}


@app.get("/api/prediccion/salud", summary="Estado del servicio")
def salud():
    return {"estado": "ok" if "predictor" in estado else "sin_modelo"}


# ───────────────────────────────── Reentrenamiento desde la app (admin) ──
#
# Flujo para Flutter:
#   1. POST /api/prediccion/reentrenar          → 202 inmediato (entrena en segundo plano)
#   2. GET  /api/prediccion/reentrenar/estado   → consultar cada pocos segundos
#   3. (opcional) POST /api/prediccion/modelo/restaurar → volver al modelo anterior
#
# Mientras entrena, el servicio sigue respondiendo con el modelo anterior.
# Antes de entrenar se guarda una copia de los artefactos en artefactos_respaldo/.

_RESPALDO_DIR = config.ARTEFACTOS_DIR.parent / f"{config.ARTEFACTOS_DIR.name}_respaldo"
_lock = threading.Lock()
_job: dict = {"estado": "inactivo"}


def _ahora() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _metricas_actuales() -> dict | None:
    """Métricas del modelo guardado en disco (o None si no hay)."""
    ruta = config.ARTEFACTOS_DIR / "metadata.json"
    if not ruta.exists():
        return None
    meta = json.loads(ruta.read_text(encoding="utf-8"))
    return {"version": meta.get("version"), "entrenado_en": meta.get("entrenado_en"),
            "ultimo_mes_real": meta.get("ultimo_mes_real"),
            "muestras_entrenamiento": meta.get("muestras_entrenamiento"),
            **(meta.get("metricas") or {})}


class _Progreso(io.TextIOBase):
    """Captura los print() de entrenar.py para mostrarlos como progreso en la app."""

    def write(self, s: str) -> int:
        for linea in s.splitlines():
            if linea.strip():
                _job["paso"] = linea.strip()
                _job.setdefault("log", []).append(linea.rstrip())
                _job["log"] = _job["log"][-40:]
        return len(s)


def _ejecutar_entrenamiento() -> None:
    import importlib

    import entrenar as modulo_entrenar

    hubo_respaldo = False
    try:
        if config.ARTEFACTOS_DIR.exists():
            if _RESPALDO_DIR.exists():
                shutil.rmtree(_RESPALDO_DIR)
            shutil.copytree(config.ARTEFACTOS_DIR, _RESPALDO_DIR)
            hubo_respaldo = True

        importlib.reload(modulo_entrenar)  # por si cambió algo en config
        with contextlib.redirect_stdout(_Progreso()):
            modulo_entrenar.main()

        estado["predictor"] = Predictor.desde_artefactos()
        _job.update(estado="completado", finalizado_en=_ahora(),
                    metricas_nuevas=_metricas_actuales(),
                    mensaje="Modelo reentrenado y cargado. Ya se usa en las predicciones.")
        logger.info("Modelo reentrenado y recargado.")
    except BaseException as e:  # SystemExit de entrenar.py (pocos datos) incluido
        logger.exception("Error durante el reentrenamiento.")
        # Si se alcanzaron a borrar los artefactos, se restaura el modelo anterior.
        if hubo_respaldo:
            if config.ARTEFACTOS_DIR.exists():
                shutil.rmtree(config.ARTEFACTOS_DIR)
            shutil.copytree(_RESPALDO_DIR, config.ARTEFACTOS_DIR)
        _job.update(estado="error", finalizado_en=_ahora(),
                    mensaje=f"No se pudo reentrenar: {str(e).rstrip('.')}. Se conserva el modelo anterior.")
    finally:
        _job["hay_respaldo"] = _RESPALDO_DIR.exists()


@app.post("/api/prediccion/reentrenar", status_code=202,
          summary="Inicia el reentrenamiento en segundo plano",
          dependencies=[Depends(verificar_api_key)])
def reentrenar():
    with _lock:
        if _job.get("estado") == "entrenando":
            raise HTTPException(409, "Ya hay un entrenamiento en curso.")
        _job.clear()
        _job.update(estado="entrenando", iniciado_en=_ahora(), paso="Iniciando…", log=[],
                    metricas_anteriores=_metricas_actuales())
    threading.Thread(target=_ejecutar_entrenamiento, daemon=True, name="reentrenar").start()
    return estado_reentrenamiento()


@app.get("/api/prediccion/reentrenar/estado",
         summary="Progreso del último reentrenamiento",
         dependencies=[Depends(verificar_api_key)])
def estado_reentrenamiento():
    return {**_job, "hay_respaldo": _RESPALDO_DIR.exists(),
            "metricas_actuales": _metricas_actuales()}


@app.post("/api/prediccion/modelo/restaurar",
          summary="Vuelve al modelo anterior al último reentrenamiento",
          dependencies=[Depends(verificar_api_key)])
def restaurar_modelo():
    if _job.get("estado") == "entrenando":
        raise HTTPException(409, "Espera a que termine el entrenamiento en curso.")
    if not _RESPALDO_DIR.exists():
        raise HTTPException(404, "No hay un modelo anterior para restaurar.")
    if config.ARTEFACTOS_DIR.exists():
        shutil.rmtree(config.ARTEFACTOS_DIR)
    shutil.move(str(_RESPALDO_DIR), str(config.ARTEFACTOS_DIR))
    estado["predictor"] = Predictor.desde_artefactos()
    _job.clear()
    _job.update(estado="inactivo", mensaje="Se restauró el modelo anterior.")
    return estado_reentrenamiento()
