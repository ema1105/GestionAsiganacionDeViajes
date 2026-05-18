"""Esquemas Pydantic de entrada/salida del microservicio de optimización."""

from typing import List, Optional

from pydantic import BaseModel, Field


class AssignRequest(BaseModel):
    """Filtros opcionales para la corrida del modelo.

    Todos tienen valor por defecto, así el endpoint puede invocarse con body vacío.
    """

    estado_viaje: str = Field(
        default="BUSCANDO_CONDUCTOR",
        description="Estado de viaje a considerar como candidato a asignación.",
    )
    solo_sin_conductor: bool = Field(
        default=True,
        description="Si es True, solo considera viajes con conductor_id NULL "
        "(viajes que todavía no tienen conductor asignado).",
    )


class Asignacion(BaseModel):
    conductor_id: int
    viaje_id: int


class AssignResponse(BaseModel):
    asignaciones: List[Asignacion]
    viajes_cubiertos: int
    total_conductores_disponibles: int
    total_viajes_pendientes: int
    status: str
