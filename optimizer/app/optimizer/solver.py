"""Resolución del modelo ILP con el solver CBC (incluido en PuLP)."""

from typing import Dict, List, Tuple

import pulp


def solve(
    problem: pulp.LpProblem,
    x: Dict[Tuple[int, int], pulp.LpVariable],
) -> Tuple[List[Tuple[int, int]], str]:
    """Resuelve el problema y devuelve (asignaciones, status).

    asignaciones: lista de tuplas (conductor_id, viaje_id) seleccionadas.
    status: estado textual del solver (Optimal, Infeasible, etc.).
    """

    # msg=0 silencia el log del solver CBC.
    problem.solve(pulp.PULP_CBC_CMD(msg=0))

    status = pulp.LpStatus[problem.status]

    asignaciones: List[Tuple[int, int]] = []
    if status == "Optimal":
        for (c, v), var in x.items():
            value = var.value()
            if value is not None and round(value) == 1:
                asignaciones.append((c, v))

    return asignaciones, status
