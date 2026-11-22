"""Carga de viajes y agregación a serie mensual de solicitudes."""
from __future__ import annotations

import pandas as pd

import config


def cargar_viajes() -> pd.DataFrame:
    """Lee los viajes desde la BD (si GAV_DB_URL está definida) o desde el CSV."""
    if config.DB_URL:
        from sqlalchemy import create_engine  # dependencia opcional

        with create_engine(config.DB_URL).connect() as con:
            df = pd.read_sql(config.SQL_VIAJES, con)
    else:
        df = pd.read_csv(config.DATA_CSV)
    faltantes = {config.COL_FECHA, config.COL_ESTADO} - set(df.columns)
    if faltantes:
        raise ValueError(f"Faltan columnas en los datos de viajes: {faltantes}")
    return df


def serie_mensual(df: pd.DataFrame, excluir_mes_en_curso: bool = True,
                  hoy: pd.Timestamp | None = None) -> pd.Series:
    """Cuenta solicitudes por mes usando solo estados finalizado/cancelado.

    - Meses sin viajes quedan en 0 (no desaparecen de la serie).
    - El mes en curso se excluye porque está incompleto y sesgaría el modelo.
    """
    estados = df[config.COL_ESTADO].astype(str).str.strip().str.lower()
    filtrado = df.loc[estados.isin(config.ESTADOS_VALIDOS)]
    fechas = pd.to_datetime(filtrado[config.COL_FECHA], errors="coerce").dropna()
    if fechas.empty:
        raise ValueError("No hay viajes finalizados/cancelados con fecha válida.")

    conteo = fechas.dt.to_period("M").value_counts().sort_index()
    rango = pd.period_range(conteo.index.min(), conteo.index.max(), freq="M")
    serie = conteo.reindex(rango, fill_value=0).astype(float)

    hoy = hoy or pd.Timestamp.now()
    if excluir_mes_en_curso and serie.index[-1] >= hoy.to_period("M"):
        serie = serie[serie.index < hoy.to_period("M")]

    serie.name = "solicitudes"
    serie.index.name = "periodo"
    return serie
