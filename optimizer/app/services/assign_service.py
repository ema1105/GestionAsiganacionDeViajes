"""Servicio de asignación: lee MySQL (solo lectura), corre el ILP y arma la respuesta.

Stateless: cada llamada abre conexión, hace SELECT, cierra. Nunca escribe en BD.
Credenciales por variables de entorno (no hardcodear).
"""

import os
from typing import List

import mysql.connector

from app.api.schemas import AssignRequest, AssignResponse, Asignacion
from app.optimizer.model import build_model
from app.optimizer.solver import solve


def _db_config() -> dict:
    """Lee la configuración de BD desde variables de entorno."""
    return {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", "3306")),
        "user": os.getenv("DB_USER", "root"),
        "password": os.getenv("DB_PASSWORD", ""),
        "database": os.getenv("DB_NAME", "gav1"),
    }


def _leer_datos(req: AssignRequest):
    """Devuelve (df_conductores, df_viajes) leídos en SOLO LECTURA."""
    conn = mysql.connector.connect(**_db_config())
    try:
        cursor = conn.cursor(dictionary=True)

        # Conductores disponibles.
        # La PK de `conductor` es `usuario_id` (entidad con @MapsId), NO `id`.
        # Se aliasa a `id` para mantener uniforme el resto del pipeline.
        cursor.execute(
            "SELECT usuario_id AS id FROM conductor WHERE disponibilidad = 1"
        )
        conductores = cursor.fetchall()

        # Viajes pendientes (estado parametrizado para evitar inyección SQL).
        sql_viajes = "SELECT id, conductor_id FROM viaje WHERE estado_viaje = %s"
        if req.solo_sin_conductor:
            sql_viajes += " AND conductor_id IS NULL"
        cursor.execute(sql_viajes, (req.estado_viaje,))
        viajes = cursor.fetchall()

        cursor.close()
    finally:
        conn.close()

    return conductores, viajes


def _ids_limpios(filas: list, clave: str) -> List[int]:
    """Extrae la columna `clave`, descarta nulos, deduplica preservando
    el orden y castea a int. Reemplaza el preprocesamiento de pandas."""
    vistos: dict = {}
    for fila in filas:
        valor = fila.get(clave)
        if valor is None:
            continue
        vistos[int(valor)] = None  # dict preserva orden y deduplica
    return list(vistos.keys())


def asignar(req: AssignRequest) -> AssignResponse:
    conductores, viajes = _leer_datos(req)

    # Preprocesamiento sin pandas: limpiar nulos/duplicados y tipar a int.
    conductor_ids: List[int] = _ids_limpios(conductores, "id")
    viaje_ids: List[int] = _ids_limpios(viajes, "id")

    total_conductores = len(conductor_ids)
    total_viajes = len(viaje_ids)

    # Sin datos suficientes: no hay nada que optimizar.
    if total_conductores == 0 or total_viajes == 0:
        return AssignResponse(
            asignaciones=[],
            viajes_cubiertos=0,
            total_conductores_disponibles=total_conductores,
            total_viajes_pendientes=total_viajes,
            status="SinDatos",
        )

    problem, x = build_model(conductor_ids, viaje_ids)
    pares, status = solve(problem, x)

    asignaciones = [
        Asignacion(conductor_id=c, viaje_id=v) for (c, v) in pares
    ]

    return AssignResponse(
        asignaciones=asignaciones,
        viajes_cubiertos=len(asignaciones),
        total_conductores_disponibles=total_conductores,
        total_viajes_pendientes=total_viajes,
        status=status,
    )
