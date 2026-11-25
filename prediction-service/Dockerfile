# prediction-service de GAV (FastAPI + TensorFlow) — RNA de demanda mensual.
# El modelo entrenado (artefactos/) va dentro de la imagen; en el servidor se
# monta un volumen en /app/artefactos para que los reentrenamientos persistan.

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    TF_CPP_MIN_LOG_LEVEL=2

WORKDIR /app

# libgomp1: requerido por TensorFlow CPU · ca-certificates: TLS hacia Azure MySQL
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 ca-certificates && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

# GAV_ARTEFACTOS_DIR (compose: /app/modelo/artefactos, en un volumen). En el primer
# arranque el volumen está vacío: se copia el modelo que viene en la imagen. Si no hay
# ninguno, se entrena. Si el entrenamiento falla, el servicio arranca igual y
# /api/prediccion/salud responde "sin_modelo".
CMD ["sh", "-c", "D=${GAV_ARTEFACTOS_DIR:-/app/artefactos}; if [ ! -f \"$D/metadata.json\" ] && [ \"$D\" != /app/artefactos ] && [ -f /app/artefactos/metadata.json ]; then mkdir -p \"$D\" && cp -r /app/artefactos/. \"$D\"/; fi; [ -f \"$D/metadata.json\" ] || python entrenar.py; exec uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --proxy-headers --forwarded-allow-ips='*'"]
