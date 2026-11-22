"""Genera data/viajes.csv con viajes simulados del hotel (solo para pruebas).

Simula la estacionalidad turística de Cartagena:
  - temporada alta: diciembre, enero, junio, julio
  - semana santa (marzo/abril) y receso de octubre: alza moderada
  - crecimiento anual ~6 % y ruido aleatorio
Incluye estados que NO entran al modelo (pendiente, asignado, en_curso)
para comprobar que el filtro funciona.

Uso:  python data/generar_datos_sinteticos.py
"""
from datetime import date, datetime, timedelta
from pathlib import Path

import numpy as np
import pandas as pd

SEMILLA = 42
INICIO = date(2021, 1, 1)
FIN = date(2026, 11, 9)
BASE_MENSUAL = 320
CRECIMIENTO_ANUAL = 0.06
ESTACIONALIDAD = {1: 1.35, 2: 0.85, 3: 1.05, 4: 1.10, 5: 0.80, 6: 1.25,
                  7: 1.30, 8: 0.95, 9: 0.75, 10: 1.05, 11: 0.90, 12: 1.45}

rng = np.random.default_rng(SEMILLA)
filas = []
mes = pd.Period(INICIO, "M")
fin = pd.Period(FIN, "M")
while mes <= fin:
    anios = (mes.ordinal - pd.Period(INICIO, "M").ordinal) / 12
    esperado = BASE_MENSUAL * (1 + CRECIMIENTO_ANUAL) ** anios * ESTACIONALIDAD[mes.month]
    n = rng.poisson(esperado * rng.normal(1, 0.05))
    ultimo_dia = min(mes.days_in_month, FIN.day) if mes == fin else mes.days_in_month
    for _ in range(n):
        dia = int(rng.integers(1, ultimo_dia + 1))
        fecha = datetime(mes.year, mes.month, dia) + timedelta(minutes=int(rng.integers(0, 1440)))
        reciente = (date(FIN.year, FIN.month, FIN.day) - fecha.date()).days < 3
        estado = (rng.choice(["pendiente", "asignado", "en_curso"]) if reciente
                  else rng.choice(["finalizado", "cancelado", "rechazado"], p=[0.86, 0.11, 0.03]))
        filas.append((fecha, estado))
    mes += 1

df = pd.DataFrame(filas, columns=["fecha_solicitud", "estado"]).sort_values("fecha_solicitud")
df.insert(0, "id", range(1, len(df) + 1))
destino = Path(__file__).resolve().parent / "viajes.csv"
df.to_csv(destino, index=False)
print(f"{len(df)} viajes generados -> {destino}")
