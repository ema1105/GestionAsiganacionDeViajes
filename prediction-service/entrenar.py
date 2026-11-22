"""Entrena el modelo de predicción de solicitudes de GAV.

Pasos:
  1. Carga viajes (BD o CSV) y arma la serie mensual (finalizados + cancelados).
  2. Backtest: entrena sin los últimos 12 meses y los predice "a ciegas".
     Calcula MAE, RMSE y MAPE, y los compara con un modelo ingenuo
     (repetir el mismo mes del año anterior).
  3. Reentrena con toda la historia y guarda los artefactos que usa la API.
  4. Genera gráficas para el informe en reportes/.

Uso:  python entrenar.py
"""
from __future__ import annotations

import json
import shutil
from datetime import datetime, timezone

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

import config
from src.datos import cargar_viajes, serie_mensual
from src.features import NOMBRES, construir_dataset, objetivo
from src.modelo import EnsambleRNA


def metricas(real: np.ndarray, pred: np.ndarray) -> dict:
    err = pred - real
    return {
        "mae": round(float(np.mean(np.abs(err))), 2),
        "rmse": round(float(np.sqrt(np.mean(err ** 2))), 2),
        "mape": round(float(np.mean(np.abs(err) / np.maximum(real, 1)) * 100), 2),
    }


def main() -> None:
    print("1/4 Cargando datos…")
    serie = serie_mensual(cargar_viajes())
    X, y, bases, periodos = construir_dataset(serie)
    print(f"    Serie: {serie.index[0]} a {serie.index[-1]} ({len(serie)} meses), "
          f"{len(y)} muestras con rezagos completos")
    if len(y) < config.MIN_MUESTRAS + config.MESES_TEST:
        raise SystemExit(f"Se necesitan al menos {config.MIN_MUESTRAS + config.MESES_TEST} "
                         f"muestras; hay {len(y)}. Faltan meses de historia.")

    # Backtest con origen rodante: cada bloque de 12 meses se predice con un
    # modelo entrenado SOLO con los meses anteriores a ese bloque.
    n_bloques = max(1, min(config.BLOQUES_BACKTEST,
                           (len(y) - config.MIN_MUESTRAS) // config.MESES_TEST))
    corte = len(y) - n_bloques * config.MESES_TEST
    print(f"2/4 Backtest rodante: {n_bloques} bloque(s) de {config.MESES_TEST} meses…")
    pred_bt, crec_medio = [], []
    for inicio in range(corte, len(y), config.MESES_TEST):
        fin = inicio + config.MESES_TEST
        ens_bt = EnsambleRNA().entrenar(X[:inicio], y[:inicio], bases[:inicio])
        pred_bt.append(ens_bt.predecir(X[inicio:fin], bases[inicio:fin])[0])
        factor = np.exp(objetivo(y[:inicio], bases[:inicio]).mean())
        crec_medio.append(bases[inicio:fin] * factor)
        print(f"    bloque {periodos[inicio]}–{periodos[fin - 1]}: "
              f"MAE RNA {metricas(y[inicio:fin], pred_bt[-1])['mae']}")
    pred_bt, crec_medio = np.concatenate(pred_bt), np.concatenate(crec_medio)
    real_bt, ingenuo = y[corte:], bases[corte:]  # ingenuo: mismo mes del año anterior

    m_rna = metricas(real_bt, pred_bt)
    m_ing = metricas(real_bt, ingenuo)
    m_crec = metricas(real_bt, crec_medio)
    mejora = round((1 - m_rna["mae"] / m_ing["mae"]) * 100, 1) if m_ing["mae"] else None
    print(f"    RNA                   -> {m_rna}")
    print(f"    Mismo mes año ant.    -> {m_ing}")
    print(f"    Crecimiento promedio  -> {m_crec}")

    print("3/4 Entrenando modelo final con toda la historia…")
    ens = EnsambleRNA().entrenar(X, y, bases)
    destino = config.ARTEFACTOS_DIR
    if destino.exists():
        shutil.rmtree(destino)
    ens.guardar(destino / "redes")
    serie.rename_axis("periodo").reset_index().assign(
        periodo=lambda d: d["periodo"].astype(str)).to_csv(destino / "serie_mensual.csv", index=False)

    epocas = [len(h["loss"]) for h in ens.historiales]
    meta = {
        "nombre": config.MODELO_NOMBRE,
        "version": config.MODELO_VERSION,
        "entrenado_en": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "origen_serie": str(serie.index[0]),
        "ultimo_mes_real": str(serie.index[-1]),
        "estados_usados": sorted(config.ESTADOS_VALIDOS),
        "variables_entrada": NOMBRES,
        "arquitectura": {
            "tipo": "Perceptrón multicapa (ensamble)",
            "capas_ocultas": list(config.CAPAS_OCULTAS),
            "activacion": config.ACTIVACION,
            "salida": "1 neurona lineal: ln(factor de crecimiento vs mismo mes año anterior)",
            "redes_en_ensamble": config.N_REDES,
            "optimizador": f"Adam (lr={config.TASA_APRENDIZAJE})",
            "regularizacion_l2": config.L2,
            "epocas_promedio": round(float(np.mean(epocas)), 1),
        },
        "muestras_entrenamiento": int(len(y)),
        "metricas": m_rna,
        "comparativo_backtest": {
            "mismo_mes_anio_anterior": m_ing,
            "crecimiento_promedio": m_crec,
            "mejora_mae_rna_vs_mismo_mes_pct": mejora,
        },
        "periodo_backtest": [str(periodos[corte]), str(periodos[-1])],
    }
    (destino / "metadata.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False),
                                           encoding="utf-8")

    print("4/4 Generando gráficas en reportes/…")
    graficas(serie, periodos[corte:], real_bt, pred_bt, ingenuo, ens)
    print(f"Listo. Artefactos en {destino}")


def graficas(serie, per_bt, real_bt, pred_bt, ingenuo, ens) -> None:
    config.REPORTES_DIR.mkdir(exist_ok=True)
    plt.rcParams.update({"figure.dpi": 130, "axes.spines.top": False, "axes.spines.right": False})

    # Backtest
    etiquetas = [str(p) for p in per_bt]
    fig, ax = plt.subplots(figsize=(11, 4))
    ax.plot(etiquetas, real_bt, "o-", color="#1f2937", label="Real")
    ax.plot(etiquetas, pred_bt, "o-", color="#2563eb", label="RNA")
    ax.plot(etiquetas, ingenuo, "o--", color="#9ca3af", label="Ingenuo (mismo mes año anterior)")
    ax.set_title("Backtest rodante: meses predichos sin haberlos visto")
    ax.set_ylabel("Solicitudes")
    ax.tick_params(axis="x", rotation=45)
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(config.REPORTES_DIR / "backtest.png")
    plt.close(fig)

    # Curvas de pérdida
    fig, ax = plt.subplots(figsize=(7, 4))
    for i, h in enumerate(ens.historiales):
        ax.plot(h["loss"], color="#2563eb", alpha=0.3, label="Entrenamiento" if i == 0 else None)
        ax.plot(h["val_loss"], color="#f97316", alpha=0.3, label="Validación" if i == 0 else None)
    ax.set_yscale("log")
    ax.set_xlabel("Época")
    ax.set_ylabel("MSE (escalado)")
    ax.set_title(f"Curvas de pérdida de las {len(ens.historiales)} redes")
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(config.REPORTES_DIR / "curvas_perdida.png")
    plt.close(fig)

    # Historia + pronóstico de 12 meses
    from src.pronostico import Predictor

    pred = Predictor.desde_artefactos()
    futuros = sorted(pred.pronosticos)[:12]
    medias = np.array([pred.pronosticos[p][0] for p in futuros])
    sigmas = np.array([pred.pronosticos[p][1] for p in futuros])
    x_hist = serie.index.to_timestamp()
    x_fut = pd.PeriodIndex(futuros).to_timestamp()
    fig, ax = plt.subplots(figsize=(10, 4))
    ax.plot(x_hist, serie.values, color="#1f2937", label="Histórico real")
    ax.plot(x_fut, medias, "o-", color="#2563eb", label="Pronóstico RNA")
    ax.fill_between(x_fut, np.maximum(medias - config.Z_INTERVALO * sigmas, 0),
                    medias + config.Z_INTERVALO * sigmas, color="#2563eb", alpha=0.15,
                    label="Intervalo ~90 %")
    ax.set_title("Solicitudes mensuales (finalizados + cancelados)")
    ax.set_ylabel("Solicitudes")
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(config.REPORTES_DIR / "pronostico.png")
    plt.close(fig)


if __name__ == "__main__":
    main()
