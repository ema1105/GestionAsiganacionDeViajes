"""Rutas HTTP del microservicio de optimización."""

from fastapi import APIRouter, HTTPException

from app.api.schemas import AssignRequest, AssignResponse
from app.services.assign_service import asignar

router = APIRouter(prefix="/api/v1", tags=["optimizer"])


@router.post("/assign", response_model=AssignResponse)
def assign(request: AssignRequest | None = None) -> AssignResponse:
    """Lee el estado actual de la BD, corre el modelo ILP y devuelve la
    asignación óptima conductor -> viaje que maximiza viajes cubiertos.

    El body es opcional; si no se envía se usan los filtros por defecto
    (estado_viaje='BUSCANDO_CONDUCTOR', solo_sin_conductor=True).
    """
    req = request or AssignRequest()
    try:
        return asignar(req)
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(
            status_code=500,
            detail=f"Error ejecutando la optimización: {exc}",
        ) from exc
