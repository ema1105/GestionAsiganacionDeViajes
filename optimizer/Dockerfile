# Microservicio de optimización (ILP) — independiente del backend Spring Boot.
FROM python:3.11-slim

# CBC (solver de PuLP) viene incluido con el paquete pulp; no requiere apt extra.
WORKDIR /app

# Instalar dependencias primero para aprovechar la caché de capas.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código del microservicio.
COPY main.py .
COPY app ./app

EXPOSE 8001

# Las credenciales de BD se inyectan por variables de entorno en runtime:
#   DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
