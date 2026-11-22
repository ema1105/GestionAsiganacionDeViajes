FROM python:3.12-slim

WORKDIR /app

# Dependencias del sistema (mínimas para TensorFlow CPU)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 && rm -rf /var/lib/apt/lists/*

# Instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código
COPY . .

EXPOSE 8000

# Si no existen artefactos, entrenar antes de arrancar.
# En producción, montar un volumen en /app/artefactos para no reentrenar en cada rebuild.
CMD ["sh", "-c", "[ -f artefactos/metadata.json ] || python entrenar.py && uvicorn app:app --host 0.0.0.0 --port 8000"]
