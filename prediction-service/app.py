"""API del prediction-service de GAV (FastAPI).

Ejecutar:  uvicorn app:app --host 0.0.0.0 --port 8000
Docs interactivas: http://localhost:8000/docs
"""
from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, Query, Request
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
    allow_methods=["GET", "POST"],
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


# ───────────────────────────────── Reentrenamiento sin reiniciar ──

@app.post("/api/prediccion/reentrenar",
          summary="Reentrena el modelo con los datos actuales y recarga",
          dependencies=[Depends(verificar_api_key)])
async def reentrenar(request: Request):
    """Ejecuta entrenar.py en un hilo aparte y recarga el Predictor.

    Mientras entrena, el servicio sigue respondiendo con el modelo anterior.
    """
    if estado.get("entrenando"):
        raise HTTPException(409, "Ya hay un entrenamiento en curso.")
    estado["entrenando"] = True
    try:
        # entrenar.py es un script pesado → correr en hilo para no bloquear
        def _entrenar():
            import importlib
            import entrenar as modulo_entrenar
            importlib.reload(modulo_entrenar)  # por si cambió algo en config
            modulo_entrenar.main()

        await asyncio.to_thread(_entrenar)

        # Recargar el predictor con los artefactos recién generados
        estado["predictor"] = Predictor.desde_artefactos()
        logger.info("Modelo reentrenado y recargado.")
        return {"resultado": "ok", "mensaje": "Modelo reentrenado y recargado."}
    except Exception as e:
        logger.exception("Error durante el reentrenamiento.")
        raise HTTPException(500, f"Error al reentrenar: {e}") from e
    finally:
        estado["entrenando"] = False
