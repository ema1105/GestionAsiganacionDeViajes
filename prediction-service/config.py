"""Configuración central del prediction-service de GAV.

Todo lo que puede cambiar entre entornos (rutas, base de datos, estados,
hiperparámetros) está aquí o se puede sobreescribir con variables de entorno.
"""
import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()  # carga .env si existe (no falla si no hay archivo)

BASE_DIR = Path(__file__).resolve().parent

# ---------------------------------------------------------------- Datos
# Fuente 1 (por defecto): CSV exportado de la tabla de viajes.
DATA_CSV = Path(os.getenv("GAV_DATA_CSV", BASE_DIR / "data" / "viajes.csv"))

# Fuente 2 (opcional): conexión directa a la BD de GAV vía SQLAlchemy.
# Ej.: postgresql+psycopg2://usuario:clave@host:5432/gav
DB_URL = os.getenv("GAV_DB_URL")
SQL_VIAJES = os.getenv(
    "GAV_SQL_VIAJES",
    "SELECT fecha_solicitud, estado_viaje AS estado FROM viaje",
)

COL_FECHA = os.getenv("GAV_COL_FECHA", "fecha_solicitud")
COL_ESTADO = os.getenv("GAV_COL_ESTADO", "estado")

# -------------------------------------------------------- Autenticación
# Si se define GAV_API_KEY, toda petición debe enviar el header
# Authorization: Bearer <clave>.  Si no se define, el servicio queda abierto
# (útil si Flutter pasa por el backend Java, que ya autentica con JWT).
# Una línea "GAV_API_KEY=" vacía en .env llega como "" (no None): se trata como no definida.
API_KEY = (os.getenv("GAV_API_KEY") or "").strip() or None

# Solo estos estados entran al modelo (decisión del equipo):
# finalizados = demanda atendida; cancelados = demanda no atendida.
ESTADOS_VALIDOS = {"finalizado", "cancelado"}

# ---------------------------------------------------------- Artefactos
ARTEFACTOS_DIR = Path(os.getenv("GAV_ARTEFACTOS_DIR", BASE_DIR / "artefactos"))
REPORTES_DIR = BASE_DIR / "reportes"

# --------------------------------------------------------------- Modelo
MODELO_NOMBRE = "RNA-MLP demanda mensual GAV"
MODELO_VERSION = "1.0.0"

CAPAS_OCULTAS = (8, 4)    # neuronas por capa oculta (pocos datos -> red pequeña)
ACTIVACION = "tanh"
L2 = 1e-2                 # regularización de pesos
TASA_APRENDIZAJE = 0.005
EPOCAS_MAX = 800
PACIENCIA = 60            # early stopping
TAMANO_LOTE = 16
FRACCION_VALIDACION = 0.2
N_REDES = 10              # tamaño del ensamble (semillas distintas)

MESES_TEST = 12           # tamaño de cada bloque de evaluación
BLOQUES_BACKTEST = 2      # años evaluados en el backtest rodante
MIN_MUESTRAS = 12         # muestras mínimas para entrenar (además de las de test)
# Cada muestra necesita 26 meses previos -> historia mínima total ≈ 26 + 12 + 12 = 50 meses

# ------------------------------------------------------------- Servicio
HORIZONTE_MAX = 12        # meses máximos hacia adelante desde el último dato real
Z_INTERVALO = 1.645       # ~90 % de confianza
UMBRAL_ESTABLE_PCT = 2.0  # |variación %| menor a esto se reporta como "estable"
