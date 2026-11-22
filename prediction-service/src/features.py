"""Variables de entrada y variable objetivo de la red neuronal.

Planteamiento: la red no predice el número de solicitudes directamente,
sino el FACTOR DE CRECIMIENTO interanual del mes:

    objetivo(t) = ln( (y_t + 1) / (y_{t-12} + 1) )
    predicción  = (y_{t-12} + 1) * e^{salida_red} - 1

Esto encaja con el caso de uso (comparar un mes con el mismo mes del año
anterior), hace al modelo independiente de la escala del hotel y evita que
la red extrapole niveles que nunca vio.

Para predecir el mes t solo se usan datos de t-12 o anteriores, así los
12 meses siguientes al último dato real se predicen directamente.
"""
from __future__ import annotations

import numpy as np
import pandas as pd

REZAGO_MAX = 26  # meses de historia que necesita cada muestra
NOMBRES = ["crec_mes", "crec_trimestre", "mes_sin", "mes_cos"]
# crec_mes:       ln(y[t-12] / y[t-24])          crecimiento interanual más reciente de ese mes
# crec_trimestre: ln(Σy[t-12..t-14] / Σy[t-24..t-26])  igual, suavizado en 3 meses
# mes_sin/cos:    mes del año codificado en círculo (dic y ene quedan cerca)


def _log_ratio(a: float, b: float) -> float:
    return float(np.log((a + 1) / (b + 1)))


def fila(valores: dict, periodo: pd.Period) -> list[float] | None:
    """Vector de entrada para `periodo`. None si falta historia."""
    try:
        v = lambda k: valores[periodo - k]  # noqa: E731
        crec_mes = _log_ratio(v(12), v(24))
        crec_trim = _log_ratio(sum(v(k) for k in (12, 13, 14)),
                               sum(v(k) for k in (24, 25, 26)))
    except KeyError:
        return None
    angulo = 2 * np.pi * (periodo.month - 1) / 12
    return [crec_mes, crec_trim, np.sin(angulo), np.cos(angulo)]


def base(valores: dict, periodo: pd.Period) -> float:
    """Valor del mismo mes del año anterior (sobre el que se aplica el factor)."""
    return float(valores[periodo - 12])


def objetivo(y: np.ndarray, base_12: np.ndarray) -> np.ndarray:
    return np.log((y + 1) / (base_12 + 1))


def reconstruir(salida: np.ndarray, base_12: np.ndarray) -> np.ndarray:
    return np.clip((base_12 + 1) * np.exp(salida) - 1, 0, None)


def construir_dataset(serie: pd.Series):
    """X, y (solicitudes reales), base (t-12) y periodos de cada muestra."""
    valores = serie.to_dict()
    X, y, bases, periodos = [], [], [], []
    for periodo, real in serie.items():
        x = fila(valores, periodo)
        if x is not None:
            X.append(x)
            y.append(real)
            bases.append(base(valores, periodo))
            periodos.append(periodo)
    return (np.array(X, dtype=float), np.array(y, dtype=float),
            np.array(bases, dtype=float), periodos)
