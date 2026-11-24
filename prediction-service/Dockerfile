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

# Si no hay modelo (volumen vacío y sin artefactos en la imagen), entrena primero.
# Si el entrenamiento falla, el servicio arranca igual y /api/prediccion/salud
# responde "sin_modelo" (más fácil de diagnosticar que un contenedor caído).
CMD ["sh", "-c", "[ -f artefactos/metadata.json ] || python entrenar.py; exec uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --proxy-headers --forwarded-allow-ips='*'"]
