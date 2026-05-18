"""Punto de entrada del microservicio de optimización (FastAPI).

Microservicio independiente y stateless. Solo lectura de MySQL.
No toca ni depende del proyecto Spring Boot.

Ejecutar:
    uvicorn main:app --host 0.0.0.0 --port 8001
o:
    python main.py
"""

import os

import uvicorn
from fastapi import FastAPI

from app.api.routes import router

app = FastAPI(
    title="GAV Optimizer Microservice",
    description="Asignación óptima conductor->viaje vía Programación Lineal Entera (ILP).",
    version="1.0.0",
)

app.include_router(router)


@app.get("/health", tags=["health"])
def health() -> dict:
    return {"status": "UP"}


if __name__ == "__main__":
    port = int(os.getenv("APP_PORT", "8001"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
