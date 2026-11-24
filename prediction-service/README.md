# GAV · prediction-service

Servicio en Python que predice cuántas **solicitudes de viaje** tendrá el hotel en un periodo futuro, usando **redes neuronales artificiales (RNA)**, y lo compara con el mismo periodo del año anterior. Esa comparación sirve para decidir si la flota debe crecer o reducirse. Reemplaza al antiguo módulo *optimizer*.

## 1. Qué se predice

| Concepto | Definición |
|---|---|
| Unidad | Solicitudes de viaje por **mes** (no por día). |
| Datos que cuentan | Solo viajes con estado **finalizado** (demanda atendida) y **cancelado** (demanda no atendida por falta de tiempo, personal, etc.). Los demás estados se descartan. |
| Periodo | Rango de meses que define el usuario (`mes` a `mes_fin`), p. ej. sep–oct. |
| Comparación | Mismo rango en el año base (por defecto, el año anterior). |
| Resultado esperado | Total predicho del periodo con un intervalo (~90 %), el total real del periodo base, la variación y la tendencia: `incremento`, `disminucion` o `estable` (|variación| < 2 %). |

## 2. Cómo funciona el modelo

**Planteamiento.** La red no predice el número de solicitudes directamente. Predice el **factor de crecimiento interanual** de cada mes:

```
salida_red  = ln( (solicitudes[t] + 1) / (solicitudes[t-12] + 1) )
predicción  = (solicitudes[t-12] + 1) · e^salida_red − 1
```

Este planteamiento tiene tres ventajas. Coincide con la pregunta del negocio ("¿sube o baja frente al año pasado?"). No depende de la escala del hotel. Y evita que la red extrapole niveles que nunca vio.

**Variables de entrada** (todas usan datos de *t−12 o antes*, así los 12 meses siguientes al último dato real se predicen directamente):

| Variable | Significado |
|---|---|
| `crec_mes` | ln(y[t−12] / y[t−24]): crecimiento interanual más reciente de ese mes |
| `crec_trimestre` | Lo mismo, sumando 3 meses (t−12..t−14 vs t−24..t−26): señal más estable |
| `mes_sin`, `mes_cos` | Mes del año codificado en círculo (diciembre y enero quedan "cerca") |

**Arquitectura** (`config.py`):

- Perceptrón multicapa: 4 entradas → 8 neuronas → 4 neuronas (tanh) → 1 salida lineal.
- Regularización L2 = 0.01. Optimizador Adam (lr = 0.005). Función de pérdida MSE.
- Early stopping (paciencia 60) sobre el 20 % más reciente de los datos de entrenamiento.
- **Ensamble de 10 redes** con semillas distintas. La predicción es el promedio. La dispersión entre redes se suma a la incertidumbre.
- Las entradas y la salida se estandarizan (StandardScaler).

**Meses más allá de 12.** Se predicen por bloques. El bloque 2 (meses 13 a 24) usa como historia las predicciones del bloque 1, por eso su intervalo es más ancho. El horizonte máximo es de 24 meses desde el último dato real.

**Intervalo.** Por mes, σ = √(g·RMSE² + σ_redes²), donde g es el bloque (1 o 2). Para el periodo se usa el total ± 1.645·√Σσ².

## 3. Evaluación (backtest rodante)

Cada bloque de 12 meses se predice con un modelo entrenado **solo con los meses anteriores** a ese bloque. El resultado se compara con dos modelos de referencia.

Resultados con los **datos sintéticos** (nov 2024 – oct 2026):

| Modelo | MAE | RMSE | MAPE |
|---|---|---|---|
| **RNA (ensamble)** | **36.4** | **45.2** | **7.96 %** |
| Mismo mes del año anterior | 37.7 | 48.4 | 8.18 % |
| Crecimiento promedio histórico | 36.3 | 46.1 | 7.94 % |

> Los datos sintéticos son crecimiento constante + ruido, así que ningún modelo puede superar mucho al de "crecimiento promedio". Con los datos reales del hotel estas cifras cambian. Por eso `entrenar.py` siempre reporta las tres comparaciones. Si la RNA no supera a las referencias, hay que decirlo en el informe.

`mae` y `rmse` del endpoint son las del backtest de la RNA.

**Historia mínima:** cada muestra necesita 26 meses previos. Con 12 de entrenamiento y 12 de prueba, el mínimo es de unos **50 meses** de datos.

## 4. Estructura

```
prediction-service/
├── app.py                  API FastAPI
├── entrenar.py             Pipeline de entrenamiento + backtest + gráficas
├── config.py               Parámetros, rutas, estados, hiperparámetros
├── src/
│   ├── datos.py            Carga (CSV o BD) y serie mensual
│   ├── features.py         Variables de entrada y objetivo
│   ├── modelo.py           Ensamble de RNA (Keras)
│   └── pronostico.py       Pronóstico y armado de la respuesta
├── data/generar_datos_sinteticos.py
├── artefactos/             (se genera) redes .keras, escaladores, metadata, serie
├── reportes/               (se genera) backtest.png, curvas_perdida.png, pronostico.png
├── tests/test_api.py
└── ejemplo_respuesta.json  Para el mock server de Flutter
```

## 5. Uso

### Requisito en Windows: habilitar rutas largas

TensorFlow tiene archivos con nombres muy largos. Sin Long Paths habilitado, `pip install` falla. **Solución (una sola vez, como Administrador):**

```powershell
# PowerShell como Administrador:
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

Reiniciar la PC y volver a ejecutar `pip install`.

### Instalación local

```bash
cd prediction-service
python -m venv .venv
# Windows: .venv\Scripts\activate  |  Linux/Mac: source .venv/bin/activate
pip install --no-cache-dir -r requirements.txt

# Copiar .env.example → .env y ajustar las variables
cp .env.example .env

# Datos de prueba (omitir si ya tienen data/viajes.csv o conexión a BD)
python data/generar_datos_sinteticos.py

python entrenar.py                 # ~2-3 min en CPU
uvicorn app:app --host 0.0.0.0 --port 8000   # docs en http://localhost:8000/docs
python -m pytest -q
```

### Datos reales

El SQL por defecto ya apunta a la tabla `viaje` con la columna `estado_viaje` (el esquema real de GAV). Si conectas la BD, solo define `GAV_DB_URL` en `.env`:

```
GAV_DB_URL=postgresql+psycopg2://lector:clave@localhost:5432/gav
```

Y descomenta el driver correspondiente en `requirements.txt` (`psycopg2-binary` para PostgreSQL, `pymysql` para MySQL, `pyodbc` para SQL Server).

También puedes exportar la tabla a CSV (`data/viajes.csv`) con las columnas `fecha_solicitud` y `estado`.

Los estados se comparan sin distinguir mayúsculas. El mes en curso se excluye siempre porque está incompleto.

### Autenticación

Si `GAV_API_KEY` está definida en `.env`, toda petición (excepto `/salud`) necesita el header:

```
Authorization: Bearer <tu-clave>
```

Si no se define, el servicio queda abierto. Esto es útil si Flutter pasa por el backend Java, que ya valida JWT.

### Reentrenamiento

Dos opciones:

1. **Desde la app (admin → Demanda mensual → Modelo predictivo)** o por API, sin reiniciar:
   - `POST /api/prediccion/reentrenar` → responde **202** de inmediato y entrena en segundo plano.
   - `GET /api/prediccion/reentrenar/estado` → `estado` (`inactivo` | `entrenando` | `completado` | `error`), `paso`, `log`, `metricas_anteriores`, `metricas_nuevas`, `metricas_actuales`, `hay_respaldo`.
   - `POST /api/prediccion/modelo/restaurar` → vuelve al modelo anterior (se respalda en `artefactos_respaldo/` antes de cada entrenamiento).
   El servicio sigue respondiendo con el modelo anterior mientras entrena; si el entrenamiento falla, se conserva el anterior.
2. **Manual**: ejecutar `python entrenar.py` y reiniciar el servicio.

### Docker

```bash
docker build -t prediction-service .
docker run -p 8000:8000 --env-file .env prediction-service
```

En `docker-compose.yml` junto al backend:

```yaml
  prediction-service:
    build: ./prediction-service
    ports: ["8000:8000"]
    env_file: ./prediction-service/.env
    volumes:
      - modelo_prediccion:/app/artefactos
    depends_on: [db]

volumes:
  modelo_prediccion:
```

## 6. Contrato del endpoint

### Petición

```
GET /api/prediccion/mensual?anio=2027&mes=9&mes_fin=10&anio_base=2026
```

| Parámetro | Obligatorio | Descripción |
|---|---|---|
| `anio` | sí | Año del periodo a predecir |
| `mes` | sí | Mes de inicio (1–12) |
| `mes_fin` | no | Mes de fin (por defecto = `mes`). Si es menor que `mes`, el rango cruza de año (nov–feb). |
| `anio_base` | no | Año de comparación (por defecto `anio − 1`) |

### Respuesta 200

```json
{
  "generado_en": "2026-11-09T21:37:31+00:00",
  "modelo": { "nombre": "RNA-MLP demanda mensual GAV", "version": "1.0.0", "mae": 36.37, "rmse": 45.2 },
  "periodo_objetivo": {
    "desde": "2027-09", "hasta": "2027-10", "etiqueta": "sep 2027 – oct 2027",
    "solicitudes_predichas": 844,
    "intervalo": { "min": 733, "max": 954 }
  },
  "periodo_base": {
    "desde": "2026-09", "hasta": "2026-10", "etiqueta": "sep 2026 – oct 2026",
    "solicitudes_reales": 765
  },
  "comparacion": { "variacion_absoluta": 79, "variacion_porcentual": 10.33, "tendencia": "incremento" },
  "otros_meses": [
    { "periodo": "2027-09", "etiqueta": "sep 2027", "solicitudes_predichas": 347,
      "solicitudes_reales_base": 315, "en_periodo": true }
    // … 12 meses en total
  ]
}
```

### Qué consume cada gráfica de la app

| Elemento en la app | Campos |
|---|---|
| Tarjeta resumen | `periodo_objetivo.solicitudes_predichas`, `intervalo`, `comparacion.tendencia` y `variacion_porcentual` |
| Barras "predicho vs año anterior" | `periodo_objetivo.solicitudes_predichas` vs `periodo_base.solicitudes_reales` |
| Velas del Histórico | `otros_meses[]`: apertura = `solicitudes_reales_base`, cierre = `solicitudes_predichas`, mecha = `intervalo` |
| Línea de 12 meses | `otros_meses[]`: `solicitudes_predichas` (línea predicha) y `solicitudes_reales_base` (línea año anterior; `null` si aún no existe). Resaltar los que tienen `en_periodo: true`. |
| Pie de confiabilidad | `modelo.mae`, `modelo.rmse`, `generado_en` |

Cada fila de `otros_meses` trae también `intervalo` (`{"min", "max"}`, ~90 %) para las mechas de las velas del Histórico; es `null` si el mes no tiene predicción.

`otros_meses` cubre enero a diciembre del año consultado. Si el rango cruza de año, cubre los 12 meses desde `mes`. Un mes fuera del horizonte trae `solicitudes_predichas: null`.

### Errores (422, `{"detail": "..."}`)

- El periodo base no tiene datos reales completos. Por ejemplo, pedir oct–nov 2027 antes de que cierre nov 2026.
- El periodo supera el horizonte de 24 meses.
- Parámetros fuera de rango, o `anio_base ≥ anio`.

### Otros endpoints

- `GET /api/prediccion/modelo`: ficha técnica, métricas y comparativo del backtest.
- `GET /api/prediccion/salud`: estado del servicio (no requiere autenticación).
- `POST /api/prediccion/reentrenar`: reentrena con los datos actuales y recarga el modelo sin reiniciar.
