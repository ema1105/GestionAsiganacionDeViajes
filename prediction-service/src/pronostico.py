"""Pronóstico de meses futuros y armado de la respuesta del endpoint.

Pronóstico recursivo por bloques de 12 meses:
  - Bloque 1 (meses 1-12 después del último dato real): sus rezagos (t-12,
    t-13, t-14) son todos datos reales -> predicción directa.
  - Bloque 2 (meses 13-24): usa como rezagos las predicciones del bloque 1.
    Su error es mayor, por eso el intervalo se ensancha por generación.
"""
from __future__ import annotations

import json
import math
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd

import config
from src.features import base, fila
from src.modelo import EnsambleRNA

MESES = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]


class ErrorPeticion(ValueError):
    """Petición válida en forma pero imposible de responder (rango, datos)."""


class Predictor:
    def __init__(self, ensamble: EnsambleRNA, serie: pd.Series, meta: dict):
        self.ens = ensamble
        self.serie = serie
        self.meta = meta
        self.ultimo_real = serie.index[-1]
        self.rmse = meta["metricas"]["rmse"]
        self.pronosticos = self._pronosticar(config.HORIZONTE_MAX)

    # ------------------------------------------------------------ carga
    @classmethod
    def desde_artefactos(cls, carpeta: Path = config.ARTEFACTOS_DIR) -> "Predictor":
        meta = json.loads((carpeta / "metadata.json").read_text(encoding="utf-8"))
        tabla = pd.read_csv(carpeta / "serie_mensual.csv")
        serie = pd.Series(tabla["solicitudes"].values,
                          index=pd.PeriodIndex(tabla["periodo"], freq="M"), name="solicitudes")
        return cls(EnsambleRNA.cargar(carpeta / "redes"), serie, meta)

    # ------------------------------------------------------- pronóstico
    def _pronosticar(self, horizonte: int) -> dict:
        """{periodo: (media, desviación_total)} para meses futuros."""
        valores = self.serie.to_dict()
        resultado = {}
        futuros = [self.ultimo_real + i for i in range(1, horizonte + 1)]
        for gen, inicio in enumerate(range(0, horizonte, 12), start=1):
            bloque = futuros[inicio:inicio + 12]
            X = np.array([fila(valores, p) for p in bloque])
            bases = np.array([base(valores, p) for p in bloque])
            medias, std_redes = self.ens.predecir(X, bases)
            for p, m, s in zip(bloque, medias, std_redes):
                valores[p] = float(m)
                # error de backtest (crece con la generación) + desacuerdo entre redes
                sigma = math.sqrt(gen * self.rmse ** 2 + float(s) ** 2)
                resultado[p] = (float(m), sigma)
        return resultado

    def _mes(self, p: pd.Period) -> tuple[float, float]:
        if p in self.pronosticos:
            return self.pronosticos[p]
        if p <= self.ultimo_real:  # mes pasado: predicción "a ciegas" con rezagos reales
            valores = self.serie.to_dict()
            x = fila(valores, p)
            if x is None:
                raise ErrorPeticion(f"No hay historia suficiente para estimar {etiqueta(p)}.")
            m, s = self.ens.predecir(np.array([x]), np.array([base(valores, p)]))
            return float(m[0]), math.sqrt(self.rmse ** 2 + float(s[0]) ** 2)
        limite = self.ultimo_real + config.HORIZONTE_MAX
        raise ErrorPeticion(f"{etiqueta(p)} supera el horizonte máximo ({etiqueta(limite)}).")

    # --------------------------------------------------------- respuesta
    def prediccion_mensual(self, anio: int, mes: int, mes_fin: int | None = None,
                           anio_base: int | None = None) -> dict:
        mes_fin = mes_fin or mes
        anio_base = anio_base or anio - 1
        objetivo = rango(anio, mes, mes_fin)
        base = rango(anio_base, mes, mes_fin)

        faltan = [etiqueta(p) for p in base if p not in self.serie.index]
        if faltan:
            raise ErrorPeticion(f"El periodo base no tiene datos reales: {', '.join(faltan)}.")

        preds = [self._mes(p) for p in objetivo]
        total = sum(m for m, _ in preds)
        margen = config.Z_INTERVALO * math.sqrt(sum(s ** 2 for _, s in preds))
        reales_base = int(sum(self.serie[p] for p in base))

        var_abs = round(total) - reales_base
        var_pct = round(var_abs / reales_base * 100, 2) if reales_base else None
        if var_pct is None or abs(var_pct) < config.UMBRAL_ESTABLE_PCT:
            tendencia = "estable" if var_pct is not None else "sin_base"
        else:
            tendencia = "incremento" if var_pct > 0 else "disminucion"

        return {
            "generado_en": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "modelo": {
                "nombre": self.meta["nombre"],
                "version": self.meta["version"],
                "mae": self.meta["metricas"]["mae"],
                "rmse": self.meta["metricas"]["rmse"],
            },
            "periodo_objetivo": {
                "desde": str(objetivo[0]), "hasta": str(objetivo[-1]),
                "etiqueta": etiqueta_rango(objetivo),
                "solicitudes_predichas": round(total),
                "intervalo": {"min": max(0, round(total - margen)), "max": round(total + margen)},
            },
            "periodo_base": {
                "desde": str(base[0]), "hasta": str(base[-1]),
                "etiqueta": etiqueta_rango(base),
                "solicitudes_reales": reales_base,
            },
            "comparacion": {
                "variacion_absoluta": var_abs,
                "variacion_porcentual": var_pct,
                "tendencia": tendencia,
            },
            "otros_meses": self._otros_meses(objetivo, anio_base - anio),
        }

    def _otros_meses(self, objetivo: list[pd.Period], desfase_base: int) -> list[dict]:
        """Serie de 12 meses para la gráfica, marcando los del periodo consultado."""
        inicio = (pd.Period(year=objetivo[0].year, month=1, freq="M")
                  if objetivo[0].year == objetivo[-1].year else objetivo[0])
        filas = []
        for p in (inicio + i for i in range(12)):
            try:
                m, s = self._mes(p)
                pred = round(m)
                # Rango ~90 % del mes (mismo criterio que el del periodo).
                margen = config.Z_INTERVALO * s
                intervalo = {"min": max(0, round(m - margen)), "max": round(m + margen)}
            except ErrorPeticion:
                pred = None
                intervalo = None
            p_base = p + 12 * desfase_base
            real = int(self.serie[p_base]) if p_base in self.serie.index else None
            filas.append({
                "periodo": str(p), "etiqueta": etiqueta(p),
                "solicitudes_predichas": pred,
                "intervalo": intervalo,
                "solicitudes_reales_base": real,
                "en_periodo": p in objetivo,
            })
        return filas


# ----------------------------------------------------------------- utilidades
def rango(anio: int, mes: int, mes_fin: int) -> list[pd.Period]:
    """Meses de `mes` a `mes_fin`. Si mes_fin < mes, el rango cruza al año siguiente."""
    inicio = pd.Period(year=anio, month=mes, freq="M")
    largo = (mes_fin - mes) % 12 + 1
    return [inicio + i for i in range(largo)]


def etiqueta(p: pd.Period) -> str:
    return f"{MESES[p.month - 1]} {p.year}"


def etiqueta_rango(periodos: list[pd.Period]) -> str:
    if len(periodos) == 1:
        return etiqueta(periodos[0])
    return f"{etiqueta(periodos[0])} – {etiqueta(periodos[-1])}"
