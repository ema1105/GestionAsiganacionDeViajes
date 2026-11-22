"""Red neuronal artificial (perceptrón multicapa) en ensamble.

Se entrenan N redes idénticas con semillas distintas y se promedia su
salida. Con series cortas (pocos años de historia) una sola red es muy
sensible a la inicialización; el ensamble estabiliza la predicción y la
dispersión entre redes sirve como medida de incertidumbre del modelo.
"""
from __future__ import annotations

import json
import os
from pathlib import Path

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "3")

import joblib
import keras
import numpy as np
from sklearn.preprocessing import StandardScaler

import config
from src.features import objetivo, reconstruir


def construir_red(n_entradas: int) -> keras.Model:
    capas = [keras.Input(shape=(n_entradas,))]
    for neuronas in config.CAPAS_OCULTAS:
        capas.append(keras.layers.Dense(
            neuronas, activation=config.ACTIVACION,
            kernel_regularizer=keras.regularizers.l2(config.L2)))
    capas.append(keras.layers.Dense(1, activation="linear"))
    red = keras.Sequential(capas)
    red.compile(optimizer=keras.optimizers.Adam(config.TASA_APRENDIZAJE), loss="mse")
    return red


class EnsambleRNA:
    def __init__(self, n_redes: int = config.N_REDES):
        self.n_redes = n_redes
        self.redes: list[keras.Model] = []
        self.historiales: list[dict] = []
        self.escala_x = StandardScaler()
        self.escala_y = StandardScaler()

    # ------------------------------------------------------- entrenamiento
    def entrenar(self, X: np.ndarray, y: np.ndarray, base_12: np.ndarray) -> "EnsambleRNA":
        """y = solicitudes reales; la red aprende el factor de crecimiento vs base_12."""
        Xs = self.escala_x.fit_transform(X)
        ys = self.escala_y.fit_transform(objetivo(y, base_12).reshape(-1, 1))
        self.redes, self.historiales = [], []
        for semilla in range(self.n_redes):
            keras.utils.set_random_seed(semilla)
            red = construir_red(X.shape[1])
            parada = keras.callbacks.EarlyStopping(
                monitor="val_loss", patience=config.PACIENCIA, restore_best_weights=True)
            hist = red.fit(Xs, ys, epochs=config.EPOCAS_MAX, batch_size=config.TAMANO_LOTE,
                           validation_split=config.FRACCION_VALIDACION,
                           callbacks=[parada], verbose=0)
            self.redes.append(red)
            self.historiales.append(hist.history)
        return self

    # ---------------------------------------------------------- predicción
    def predecir(self, X: np.ndarray, base_12: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
        """Solicitudes predichas: media y desviación estándar entre las redes."""
        Xs = self.escala_x.transform(np.atleast_2d(X)).astype("float32")
        salidas = np.stack([red(Xs, training=False).numpy().ravel() for red in self.redes])
        salidas = self.escala_y.inverse_transform(salidas.reshape(-1, 1)).reshape(salidas.shape)
        solicitudes = reconstruir(salidas, np.asarray(base_12, dtype=float))
        return solicitudes.mean(axis=0), solicitudes.std(axis=0)

    # -------------------------------------------------------- persistencia
    def guardar(self, carpeta: Path) -> None:
        carpeta.mkdir(parents=True, exist_ok=True)
        for i, red in enumerate(self.redes):
            red.save(carpeta / f"red_{i:02d}.keras")
        joblib.dump({"x": self.escala_x, "y": self.escala_y}, carpeta / "escaladores.joblib")
        (carpeta / "historiales.json").write_text(json.dumps(self.historiales))

    @classmethod
    def cargar(cls, carpeta: Path) -> "EnsambleRNA":
        archivos = sorted(carpeta.glob("red_*.keras"))
        if not archivos:
            raise FileNotFoundError(f"No hay redes entrenadas en {carpeta}. Ejecute entrenar.py")
        ens = cls(n_redes=len(archivos))
        ens.redes = [keras.models.load_model(a) for a in archivos]
        esc = joblib.load(carpeta / "escaladores.joblib")
        ens.escala_x, ens.escala_y = esc["x"], esc["y"]
        return ens
