"""Construcción del modelo de Programación Lineal Entera (ILP).

Problema de asignación bipartita: maximizar la cantidad de viajes pendientes
cubiertos por los conductores disponibles.

Variables:
    x[c, v] in {0, 1}  -> 1 si el conductor c es asignado al viaje v.

Objetivo:
    max sum(x[c, v])   (maximizar viajes cubiertos)

Restricciones:
    - Cada viaje recibe a lo sumo un conductor:    sum_c x[c, v] <= 1   (para todo v)
    - Cada conductor cubre a lo sumo un viaje:      sum_v x[c, v] <= 1   (para todo c)
"""

from typing import Dict, List, Tuple

import pulp


def build_model(
    conductor_ids: List[int],
    viaje_ids: List[int],
) -> Tuple[pulp.LpProblem, Dict[Tuple[int, int], pulp.LpVariable]]:
    """Crea el problema ILP y el diccionario de variables de decisión.

    Se modela el grafo bipartito completo (cualquier conductor puede cubrir
    cualquier viaje pendiente), ya que no hay restricciones de compatibilidad
    definidas en el alcance.
    """

    problem = pulp.LpProblem("AsignacionConductoresViajes", pulp.LpMaximize)

    x: Dict[Tuple[int, int], pulp.LpVariable] = {}
    for c in conductor_ids:
        for v in viaje_ids:
            x[(c, v)] = pulp.LpVariable(f"x_{c}_{v}", cat=pulp.LpBinary)
    # Con cuantos conductores min puedes cubrir n cantidad de viajes
    # Objetivo: maximizar el total de viajes cubiertos.
    problem += pulp.lpSum(x.values()), "TotalViajesCubiertos"

    # Cada viaje a lo sumo un conductor.
    for v in viaje_ids:
        problem += (
            pulp.lpSum(x[(c, v)] for c in conductor_ids) <= 1,
            f"Viaje_{v}_un_conductor",
        )

    # Cada conductor a lo sumo un viaje.
    for c in conductor_ids:
        problem += (
            pulp.lpSum(x[(c, v)] for v in viaje_ids) <= 1,
            f"Conductor_{c}_un_viaje",
        )

    return problem, x
