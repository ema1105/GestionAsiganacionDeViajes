# GAV · Backend (Spring Boot) y Modelo Predictivo (prediction-service)

Backend de **GAV – Gestión y Asignación de Viajes**, proyecto de aula de VIII semestre de Ingeniería de Sistemas (Fundación Universitaria Tecnológico Comfenalco, Cartagena). Cliente del proyecto: **Hotel Estelar Manzanillo del Mar**.

La rama `Backend` contiene dos servicios:

| Servicio | Tecnología | Puerto | Qué hace |
|---|---|---|---|
| **API principal** (`/`) | Java 21 · Spring Boot 4 · MySQL | `8080` | Usuarios y roles (JWT), viajes, asignación FIFO de conductores, GPS y seguimiento, calificaciones, notificaciones, estadísticas, chatbot y flota en vivo. |
| **prediction-service** (`/prediction-service`) | Python · FastAPI · TensorFlow/Keras | `8000` | Predice cuántas **solicitudes de viaje** tendrá el hotel en un periodo, con **redes neuronales artificiales**, y lo compara con el mismo periodo del año anterior para decidir si la flota debe crecer o reducirse. |

La app que los consume (Flutter: cliente, conductor y admin) está en la rama `front-flutter`.

```
 App Flutter (web / Android / iOS)
   │  JWT                                  │  (directo, API key opcional)
   ▼                                       ▼
 Spring Boot :8080  ───── MySQL (gav1) ◄── prediction-service :8000
   │                                       (lee viajes para entrenar)
   └── Google Gemini (chatbot)
```

---

## Tabla de contenido

1. [Tecnologías](#1-tecnologías)
2. [Estructura del proyecto](#2-estructura-del-proyecto)
3. [Puesta en marcha](#3-puesta-en-marcha)
4. [Configuración](#4-configuración)
5. [Seguridad y roles](#5-seguridad-y-roles)
6. [Modelo de datos](#6-modelo-de-datos)
7. [Ciclo de vida de un viaje](#7-ciclo-de-vida-de-un-viaje)
8. [Asignación FIFO](#8-asignación-fifo)
9. [GPS, seguimiento y flota en vivo](#9-gps-seguimiento-y-flota-en-vivo)
10. [Precio del viaje](#10-precio-del-viaje)
11. [Endpoints REST](#11-endpoints-rest)
12. [Modelo predictivo (prediction-service)](#12-modelo-predictivo-prediction-service)
13. [Problemas frecuentes](#13-problemas-frecuentes)

---

## 1. Tecnologías

### API principal
| Componente | Tecnología |
|---|---|
| Lenguaje | Java 21 |
| Framework | Spring Boot 4.0.5 (Web MVC, Data JPA, Security, Validation, Actuator) |
| Build | Maven (wrapper `mvnw`) |
| Persistencia | Spring Data JPA + Hibernate · MySQL 8 (`mysql-connector-j`) |
| Seguridad | Spring Security + JWT (`jjwt` 0.12.6), sesiones *stateless* |
| Documentación | SpringDoc OpenAPI (Swagger UI) |
| Utilidades | Lombok, MapStruct |
| Tareas programadas | `@EnableScheduling` (revisor de la cola FIFO) |
| Externos | Google Gemini (`gemini-2.5-flash`) para el chatbot; Power BI embebido en el dashboard del admin |

### prediction-service
| Componente | Tecnología |
|---|---|
| Lenguaje | Python 3.12 |
| API | FastAPI + Uvicorn |
| Modelo | TensorFlow / Keras 3 (perceptrón multicapa en ensamble) |
| Datos | pandas, NumPy, scikit-learn (escaladores), SQLAlchemy + PyMySQL |
| Gráficas del informe | Matplotlib |
| Pruebas | pytest + httpx |

---

## 2. Estructura del proyecto

```
gav/
├── pom.xml
├── src/main/java/com/GAV/gav/
│   ├── GavApplication.java          @EnableScheduling
│   ├── Config/                      Seeders: admin, roles, categorías de vehículo, lugares de Cartagena, tarifa
│   ├── Controller/                  REST: Auth, Admin, Cliente, Conductor, Recepcionista, Notificacion, Chatbot
│   ├── DTO/Request · DTO/Response   Contratos de entrada/salida (sin exponer entidades)
│   ├── Exception/                   BusinessException + GlobalExceptionHandler (JSON uniforme)
│   ├── Model/                       Entidades JPA
│   ├── Repository/                  Spring Data JPA (consultas JPQL del FIFO, estadísticas, etc.)
│   ├── Security/                    JwtService, JwtAuthFilter, SecurityConfig, manejadores 401/403
│   └── Service/                     Lógica de negocio (ViajeService = FIFO + scheduler)
├── src/main/resources/
│   ├── application.properties       Perfil por defecto (dev), BD, JPA, logs, CORS
│   ├── application-dev.properties
│   └── secrets.properties           (NO se versiona) claves privadas
└── prediction-service/              Modelo predictivo (ver sección 12)
```

Flujo de capas: **Controller → Service → Repository → MySQL**. Los controladores obtienen el usuario autenticado del JWT (`AuthenticatedUserProvider`) y nunca reciben el id del usuario por parámetro.

> `AsignacionController` / `OptimizadorService` pertenecen al antiguo módulo *optimizer* (optimización ILP), que se reemplazó por el prediction-service. La asignación real de viajes es el FIFO de `ViajeService`.

---

## 3. Puesta en marcha

### Requisitos
- JDK 21
- MySQL 8 en `localhost:3306` con la base de datos `gav1`
- (Para el modelo) Python 3.12

### API principal

```bash
# 1. Crear la base de datos (las tablas las crea Hibernate al arrancar)
mysql -u root -p -e "CREATE DATABASE gav1 CHARACTER SET utf8mb4;"

# 2. Crear src/main/resources/secrets.properties (ver sección 4)

# 3. Arrancar
./mvnw spring-boot:run          # Windows: mvnw.cmd spring-boot:run
```

- API: `http://localhost:8080`
- Swagger UI: `http://localhost:8080/swagger-ui.html`

Al primer arranque, los *seeders* crean los roles, el usuario administrador, las categorías de vehículo, el catálogo de lugares de Cartagena y una tarifa activa.

**Esquema:** `spring.jpa.hibernate.ddl-auto=update` crea las tablas y columnas faltantes, pero **no modifica las que ya existen**. Si una columna cambia de tipo (por ejemplo, las coordenadas a `DECIMAL(10,7)`), hay que hacer el `ALTER TABLE` a mano.

### prediction-service

```bash
cd prediction-service
python -m venv .venv
# Windows: .venv\Scripts\activate   |   Linux/Mac: source .venv/bin/activate
pip install --no-cache-dir -r requirements.txt

cp .env.example .env        # y definir GAV_DB_URL (ver 12.6)

python entrenar.py          # primer entrenamiento (~2-5 min en CPU)
uvicorn app:app --host 0.0.0.0 --port 8000
```

- Documentación interactiva: `http://localhost:8000/docs`
- En Windows, TensorFlow necesita las **rutas largas** habilitadas (PowerShell como administrador):
  ```powershell
  New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
  ```
  Luego reinicia el equipo.

### Docker (prediction-service)

```bash
cd prediction-service
docker build -t gav-prediction .
docker run -p 8000:8000 --env-file .env -v gav_modelo:/app/artefactos gav-prediction
```

Si no hay modelo, el contenedor entrena antes de arrancar. El volumen evita reentrenar en cada *rebuild*.

---

## 4. Configuración

### `application.properties` (API principal)

| Propiedad | Valor / uso |
|---|---|
| `spring.profiles.active` | `dev` (siempre la misma BD) |
| `spring.datasource.url` | `jdbc:mysql://127.0.0.1:3306/gav1?useSSL=false&serverTimezone=UTC` |
| `spring.jpa.hibernate.ddl-auto` | `update` (nunca `create` ni `create-drop`, porque borran datos) |
| `spring.jpa.show-sql` | `false`. Para ver el SQL: `true` y `logging.level.org.hibernate.SQL=DEBUG` |
| `jwt.expiration` | `86400000` (24 h) |
| `cors.allowed-origins` | `http://localhost:5173,http://localhost:3000,http://localhost:5000` (5000 = Flutter web) |
| `chatbot.*` | URL de Gemini, timeout y número de lugares usados como contexto |

### `secrets.properties` (no se versiona)

Se carga con `spring.config.import`. Ejemplo:

```properties
CHATBOT_API_KEY=tu_clave_de_gemini
# Recomendado mover aquí también:
# spring.datasource.password=...
# jwt.secret=...
# admin.seed.password=...
```

> ⚠️ Las credenciales de la BD, `jwt.secret` y la contraseña inicial del admin (`admin.seed.*`, por defecto `admin` / `admin123`) deben vivir en `secrets.properties` o en variables de entorno, no en `application.properties`. Cambia la contraseña del admin después del primer arranque.

### `prediction-service/.env` (no se versiona)

| Variable | Uso |
|---|---|
| `GAV_DB_URL` | Conexión a la BD de GAV, p. ej. `mysql+pymysql://usuario:clave@localhost:3306/gav1`. Sin ella se lee `data/viajes.csv`. |
| `GAV_SQL_VIAJES` | Consulta de viajes (por defecto `SELECT fecha_solicitud, estado_viaje AS estado FROM viaje`). |
| `GAV_API_KEY` | Si se define, toda petición (excepto `/salud`) exige `Authorization: Bearer <clave>`. |
| `GAV_ARTEFACTOS_DIR` | Carpeta del modelo entrenado (por defecto `artefactos/`). |

---

## 5. Seguridad y roles

- **Login:** `POST /api/auth/login` devuelve un JWT (24 h) con el rol. Cada petición lo envía en `Authorization: Bearer <token>`.
- **Sin sesión de servidor** (`STATELESS`). Un token ausente, inválido o vencido da **401**; un rol insuficiente da **403**.
- **Acceso por rol** (`SecurityConfig`):

| Ruta | Rol |
|---|---|
| `/api/auth/**`, Swagger | Público |
| `/api/admin/**` | `ADMIN` |
| `/api/recepcionista/**` | `RECEPCIONISTA` |
| `/api/cliente/**` | `CLIENTE` |
| `/api/conductor/**` | `CONDUCTOR` |
| `/api/notificaciones/**` | Cualquier usuario autenticado |

- **Conductores deshabilitados** (`activo = false`, *soft delete*): no pueden iniciar sesión, no entran al FIFO y no aparecen en la flota en vivo. Sus viajes históricos se conservan.

---

## 6. Modelo de datos

| Entidad (tabla) | Descripción |
|---|---|
| `Usuario` (`usuario`) | Datos personales, credenciales y rol. |
| `Rol` | `ADMIN`, `RECEPCIONISTA`, `CLIENTE`, `CONDUCTOR`. |
| `Conductor` (`conductor`) | Licencia, vehículo, `disponibilidad`, `activo`, `fechaDisponibleDesde` (orden FIFO), `ultimaConexion` (latido de la app) y última posición (`ultimaLat`, `ultimaLng`, `ultimaUbicacionEn`). |
| `Automovil` · `CategoriaVehiculo` | Vehículo (marca, modelo, placa, capacidad) y su categoría (CONFORT, PREMIUM, XL…). |
| `Viaje` (`viaje`) | Origen y destino (coordenadas `DECIMAL(10,7)` y nombres legibles), pasajeros, estado, precio, fechas, cliente, conductor y lugar del catálogo. |
| `ViajeConductor` (`viaje_conductor`) | Cada oferta del FIFO: `PENDIENTE`, `ACEPTADO`, `RECHAZADO` o `EXPIRADO`, con fecha de expiración. |
| `SeguimientoViaje` | Puntos GPS durante un viaje (lo que ve el cliente). |
| `UbicacionConductor` | Historial de posiciones del conductor (latido cada ~10 s). |
| `Calificacion` | Bidireccional: `CLIENTE_A_CONDUCTOR` o `CONDUCTOR_A_CLIENTE`, puntuación 1–5 y comentario; una por viaje y dirección. |
| `Notificacion` | Avisos por usuario (nueva solicitud, viaje cancelado, alta demanda, nueva calificación…). |
| `Lugar` | Catálogo de lugares de Cartagena (hoteles, playas, centros comerciales, zona histórica…) para los "destinos más solicitados" y el chatbot. |
| `Tarifa` | Precio base, por km, por minuto y multiplicador dinámico; una tarifa activa. |

---

## 7. Ciclo de vida de un viaje

```
SOLICITADO → BUSCANDO_CONDUCTOR → ACEPTADO → EN_CAMINO → EN_CURSO → FINALIZADO
                     │                 │           │
                     └─────────────────┴───────────┴──► CANCELADO (cliente, conductor o admin)
```

| Paso | Quién | Endpoint |
|---|---|---|
| Solicitar (precio calculado en el servidor) | Cliente | `POST /api/cliente/viajes` |
| Aceptar / rechazar la oferta | Conductor | `POST /api/conductor/viajes/{id}/responder?aceptar=` |
| Voy en camino | Conductor | `POST /api/conductor/viajes/{id}/en-camino` |
| Iniciar viaje | Conductor | `POST /api/conductor/viajes/{id}/iniciar` |
| Finalizar viaje (el conductor vuelve al FIFO) | Conductor | `POST /api/conductor/viajes/{id}/finalizar` |
| Calificar al conductor | Cliente | `POST /api/cliente/viajes/{id}/calificar` |
| Calificar al cliente | Conductor | `POST /api/conductor/viajes/{id}/calificar-cliente` |
| Cancelar | Cliente (hasta `EN_CAMINO`) o conductor | `…/viajes/{id}/cancelar` |

---

## 8. Asignación FIFO

Lógica en `ViajeService`:

1. Al solicitar un viaje, se ofrece al conductor que más tiempo lleva esperando (`fechaDisponibleDesde ASC`) y que cumple **todas** estas condiciones:
   - `disponibilidad = true` (no tiene viaje en curso);
   - habilitado (`activo` true o nulo);
   - **conectado**: su app dio señal en los últimos **30 s** (`ultimaConexion`);
   - vehículo con capacidad suficiente para los pasajeros;
   - no rechazó ni dejó vencer este mismo viaje.
2. El conductor tiene **30 s** para responder.
3. Un **revisor automático** (`@Scheduled`, cada **5 s**):
   - vence las ofertas sin respuesta y las de conductores que se desconectaron, y pasa al siguiente de la cola;
   - reintenta los viajes de los **últimos 30 min** que esperan conductor sin ninguna oferta en curso (solo si hay alguien conectado).
4. Si la cola se agota y todos rechazaron, se notifica **alta demanda** al cliente y se reinicia el ciclo.

**Cómo se sabe que un conductor está conectado:** su app consulta `GET /api/conductor/solicitudes/pendiente` cada ~6 s y envía `POST /api/conductor/ubicacion` cada ~10 s. Las dos actualizan `ultimaConexion`.

---

## 9. GPS, seguimiento y flota en vivo

- **`POST /api/conductor/ubicacion`** (cada ~10 s mientras la app está abierta):
  - guarda una fila en `ubicacion_conductor`;
  - actualiza en `conductor` la última posición y la hora de conexión.
- **`POST /api/conductor/viajes/{id}/seguimiento`:** puntos GPS durante el viaje. El cliente los lee con `GET /api/cliente/viajes/{id}/seguimiento/ultima`.
- **`GET /api/cliente/conductores-cercanos`:** conductores disponibles en un radio (Haversine).
- **`GET /api/admin/flota/ubicaciones`** (Flota en vivo):
  - devuelve los conductores habilitados con señal en los últimos 30 s;
  - para cada uno: posición, vehículo, placa, hora de la última señal, estado (`DISPONIBLE` / `EN_VIAJE`) y, si va en viaje, el viaje con su origen y destino;
  - quien cierra sesión o es deshabilitado deja de aparecer.

> La ubicación del conductor es un dato personal (Ley 1581 de 2012): solo se expone mientras tiene la sesión abierta.
>
> `ubicacion_conductor` crece rápido (≈ 6 filas por minuto por conductor). Para producción se recomienda un índice `(conductor_id, fecha)` y depurar los registros de más de 30 días.

---

## 10. Precio del viaje

```
precio = (precioBase + precioPorKm × km + precioPorMinuto × minutos) × multiplicadorDinamico
```

- La distancia y la duración las calcula la app con Google (Routes/Directions) y las envía al solicitar.
- El precio **siempre lo calcula el servidor** con la tarifa activa.
- `GET /api/cliente/viajes/cotizar` usa la misma fórmula, así que lo cotizado es lo que se cobra.

---

## 11. Endpoints REST

La lista completa, con opción de probar cada endpoint, está en **Swagger UI** (`/swagger-ui.html`). Resumen:

### Autenticación — `/api/auth`
`POST /login` · `POST /register/cliente`

### Cliente — `/api/cliente`
| Método y ruta | Descripción |
|---|---|
| `POST /viajes` · `GET /viajes/cotizar` | Solicitar viaje · cotizar precio |
| `GET /viaje-activo` (204 si no hay) · `GET /viajes/{id}` · `GET /viajes/{id}/detalle` | Viaje actual y detalle |
| `GET /viajes` (paginado, filtros) · `GET /viajes/mis` | Historial |
| `POST /viajes/{id}/cancelar` | Cancelar |
| `GET /viajes/{id}/seguimiento/ultima` · `GET /viajes/{id}/seguimiento` | Posición del conductor · recorrido |
| `POST /viajes/{id}/calificar` · `GET /calificaciones` · `GET /calificaciones/promedio` | Calificaciones |
| `GET /conductores-cercanos` · `GET /lugares/mas-solicitados` | Mapa e inicio |
| `POST /chatbot/mensaje` | Asistente (Gemini) |
| `GET/PUT /perfil` | Perfil |

### Conductor — `/api/conductor`
| Método y ruta | Descripción |
|---|---|
| `GET /solicitudes/pendiente` (204 si no hay) · `GET /solicitudes` | Oferta actual (también es el latido de conexión) · historial de ofertas |
| `POST /viajes/{id}/responder?aceptar=` | Aceptar o rechazar |
| `POST /viajes/{id}/en-camino` · `/iniciar` · `/finalizar` · `/cancelar` | Avanzar o cancelar el viaje |
| `GET /viaje-activo` · `GET /viajes/{id}/detalle` · `GET /viajes/en-proceso` | Viaje actual (detalle con contacto del cliente) |
| `GET /viajes` | Historial paginado |
| `POST /ubicacion` · `POST /viajes/{id}/seguimiento` · `GET /viajes/{id}/seguimiento` | GPS |
| `POST /viajes/{id}/calificar-cliente` · `GET /calificaciones` · `GET /calificaciones/promedio` | Calificaciones |
| `GET /estadisticas/ganancias/dia·mes` · `GET /estadisticas/viajes/dia·mes` | Ganancias y viajes |
| `GET/PUT /perfil` | Perfil |

### Administrador — `/api/admin`
| Método y ruta | Descripción |
|---|---|
| `POST/GET /conductores` · `GET/PUT/DELETE /conductores/{id}` · `POST /conductores/{id}/deshabilitar·habilitar` | Conductores |
| `POST/GET /vehiculos` · `GET/PUT/DELETE /vehiculos/{id}` · `GET /categorias` | Vehículos |
| `POST /conductores/{cId}/vehiculo/{vId}` · `DELETE /conductores/{cId}/vehiculo` | Asignar o quitar vehículo |
| `GET /clientes` · `GET /viajes` (filtro por estado) · `GET /viajes/{id}/seguimiento` | Consultas |
| `GET /estadisticas/ganancias/dia·mes` · `GET /estadisticas/viajes/dia` · `GET /estadisticas/viajes/por-dia` | Estadísticas |
| `GET /flota/ubicaciones` | Flota en vivo |
| `GET /dashboard/url` | URL del dashboard Power BI |
| `GET/PUT /perfil` | Perfil |

### Recepcionista — `/api/recepcionista`
`POST /clientes` (registrar huésped) · `POST /clientes/{id}/viajes` (pedir viaje en su nombre) · `GET /viajes` · `GET /viajes/{id}` · `GET /conductores`

### Notificaciones — `/api/notificaciones`
`GET /mias` · `GET /no-leidas` · `GET /no-leidas/count` · `PUT /{id}/leer` · `PUT /leer-todas`

### Formato de errores
`GlobalExceptionHandler` responde JSON uniforme con `mensaje` y, en validaciones, `errores` por campo. `BusinessException` lleva su propio código HTTP (400, 403, 404, 409…).

---

## 12. Modelo predictivo (prediction-service)

Servicio en Python que predice cuántas **solicitudes de viaje** tendrá el hotel en un periodo futuro, usando **redes neuronales artificiales (RNA)**, y lo compara con el mismo periodo del año anterior. Reemplaza al antiguo módulo *optimizer*.

### 12.1 Qué se predice

| Concepto | Definición |
|---|---|
| Unidad | Solicitudes de viaje por **mes** (no por día). |
| Datos que cuentan | Solo viajes **FINALIZADOS** (demanda atendida) y **CANCELADOS** (demanda no atendida por falta de tiempo, de personal, etc.). Los demás estados se descartan. |
| Periodo | Rango de meses que elige el usuario (de `mes` a `mes_fin`), p. ej. oct–nov. |
| Comparación | El mismo rango en el año base (por defecto, el año anterior): oct–nov 2027 vs oct–nov 2026. |
| Resultado | Total predicho con intervalo de ~90 %, total real del periodo base, variación absoluta y porcentual, y tendencia: `incremento`, `disminucion` o `estable` (\|variación\| < 2 %). |
| Para qué sirve | Decidir si la flota del hotel debe **crecer o reducirse** en ese periodo. |

### 12.2 Cómo funciona el modelo

**Planteamiento.** La red no predice el número de solicitudes directamente, sino el **factor de crecimiento interanual** de cada mes:

```
salida_red = ln( (solicitudes[t] + 1) / (solicitudes[t-12] + 1) )
predicción = (solicitudes[t-12] + 1) · e^salida_red − 1
```

Este planteamiento coincide con la pregunta del negocio ("¿sube o baja frente al año pasado?"), no depende de la escala del hotel y evita que la red extrapole niveles que nunca vio.

**Variables de entrada.** Todas usan datos de *t−12 o antes*, así que los 12 meses siguientes al último dato real se predicen directamente:

| Variable | Significado |
|---|---|
| `crec_mes` | ln(y[t−12] / y[t−24]): crecimiento interanual más reciente de ese mes |
| `crec_trimestre` | Lo mismo sumando 3 meses: una señal más estable |
| `mes_sin`, `mes_cos` | Mes del año codificado en círculo (diciembre y enero quedan "cerca") |

**Arquitectura** (`config.py`):
- Perceptrón multicapa: 4 entradas → 8 neuronas → 4 neuronas (tanh) → 1 salida lineal.
- Regularización L2 = 0.01, optimizador Adam (lr = 0.005), pérdida MSE.
- *Early stopping* (paciencia 60) sobre el 20 % más reciente de los datos de entrenamiento.
- **Ensamble de 10 redes** con semillas distintas: la predicción es el promedio y la dispersión entre redes se suma a la incertidumbre.
- Entradas y salida estandarizadas (StandardScaler).

**Horizonte.** Máximo 24 meses desde el último dato real. Los meses 13–24 usan como historia las predicciones del primer bloque, por eso su intervalo es más ancho.

**Intervalo.** Por mes, σ = √(g·RMSE² + σ_redes²), donde g es el bloque (1 o 2). Para el periodo se usa el total ± 1.645·√Σσ².

**Historia mínima.** Cada muestra necesita 26 meses previos. Con 12 meses de entrenamiento y 12 de prueba, hacen falta unos **50 meses** de datos.

**El mes en curso se excluye**, porque está incompleto y sesgaría el modelo.

### 12.3 Evaluación (backtest rodante)

Cada bloque de 12 meses se predice con un modelo entrenado **solo con los meses anteriores** a ese bloque, y se compara con dos modelos de referencia:

| Modelo | MAE | RMSE | MAPE |
|---|---|---|---|
| **RNA (ensamble)** | **36.4** | **45.2** | **7.96 %** |
| Mismo mes del año anterior | 37.7 | 48.4 | 8.18 % |
| Crecimiento promedio histórico | 36.3 | 46.1 | 7.94 % |

*Resultados con los datos sintéticos (nov 2024 – oct 2026).* Esos datos son crecimiento constante más ruido, así que ningún modelo supera por mucho al "crecimiento promedio". Con datos reales del hotel las cifras cambian, por eso `entrenar.py` siempre reporta las tres comparaciones. Los valores `mae` y `rmse` que entrega la API son los del backtest de la RNA.

### 12.4 Estructura

```
prediction-service/
├── app.py                    API FastAPI (predicción + reentrenamiento en segundo plano)
├── entrenar.py               Carga → backtest → entrenamiento final → artefactos → gráficas
├── config.py                 Parámetros, rutas, estados válidos e hiperparámetros
├── src/
│   ├── datos.py              Carga (BD o CSV) y serie mensual
│   ├── features.py           Variables de entrada y objetivo
│   ├── modelo.py             Ensamble de RNA (Keras)
│   └── pronostico.py         Pronóstico y armado de la respuesta
├── data/generar_datos_sinteticos.py
├── artefactos/               (se genera) redes .keras, escaladores, metadata.json, serie
├── artefactos_respaldo/      (se genera) copia del modelo anterior a cada reentrenamiento
├── reportes/                 (se genera) backtest.png, curvas_perdida.png, pronostico.png
├── tests/test_api.py
├── ejemplo_respuesta.json    Respuesta de ejemplo (mock para la app)
└── Dockerfile
```

### 12.5 API

| Método y ruta | Auth | Descripción |
|---|---|---|
| `GET /api/prediccion/mensual?anio=&mes=&mes_fin=&anio_base=` | API key* | Predicción del periodo vs año base |
| `GET /api/prediccion/modelo` | API key* | Ficha técnica, métricas y horizonte disponible |
| `GET /api/prediccion/salud` | — | `{"estado": "ok" \| "sin_modelo"}` |
| `POST /api/prediccion/reentrenar` | API key* | Inicia el reentrenamiento **en segundo plano** (202) |
| `GET /api/prediccion/reentrenar/estado` | API key* | Progreso: `estado` (`inactivo` · `entrenando` · `completado` · `error`), `paso`, `log`, `metricas_anteriores`, `metricas_nuevas`, `metricas_actuales`, `hay_respaldo` |
| `POST /api/prediccion/modelo/restaurar` | API key* | Vuelve al modelo anterior al último reentrenamiento |

\* Solo si `GAV_API_KEY` está definida.

**Ejemplo:** `GET /api/prediccion/mensual?anio=2027&mes=9&mes_fin=10`

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
      "solicitudes_reales_base": 315, "en_periodo": true, "intervalo": { "min": 300, "max": 394 } }
  ]
}
```

- `otros_meses` cubre los 12 meses del año consultado (o los 12 desde `mes` si el rango cruza de año). Alimenta las gráficas de la app.
- **Errores 422** (`{"detail": "..."}`):
  - el periodo base aún no tiene datos reales completos;
  - el periodo supera el horizonte;
  - `anio_base ≥ anio` o parámetros fuera de rango.

### 12.6 Datos

- Con `GAV_DB_URL` definida, el servicio lee directamente la tabla `viaje` de MySQL:
  ```
  GAV_DB_URL=mysql+pymysql://usuario:clave@localhost:3306/gav1
  ```
- Sin BD, lee `data/viajes.csv` (columnas `fecha_solicitud` y `estado`). Para pruebas: `python data/generar_datos_sinteticos.py`.
- Los estados se comparan sin distinguir mayúsculas.

### 12.7 Reentrenamiento

- **Desde la app** (Admin → Predicción → Modelo predictivo) o por API, **sin reiniciar el servicio**:
  1. `POST /api/prediccion/reentrenar` responde de inmediato; el modelo actual sigue respondiendo mientras tanto.
  2. Antes de entrenar se copia el modelo vigente a `artefactos_respaldo/`.
  3. Al terminar, el modelo nuevo se carga solo. Si falla (por ejemplo, por falta de meses de historia), se conserva el anterior.
  4. `POST /api/prediccion/modelo/restaurar` vuelve al modelo previo si el nuevo tiene más error.
- **Manual:** `python entrenar.py` y reiniciar `uvicorn`.

### 12.8 Pruebas

```bash
cd prediction-service
python -m pytest -q
```

---

## 13. Problemas frecuentes

| Síntoma | Causa / solución |
|---|---|
| La consola se llena de SQL | `spring.jpa.show-sql=false` y `logging.level.org.hibernate.SQL=INFO` (ya vienen así). |
| Coordenadas con 2 decimales, distancias "0,0 km" | Columnas antiguas `DECIMAL(38,2)`. Ejecuta `ALTER TABLE viaje MODIFY origen_lat DECIMAL(10,7), …`, igual en `seguimiento_viaje`, `ubicacion_conductor` y `lugar`. |
| Error 1175 de MySQL Workbench en un `UPDATE` | *Safe update mode*: ejecuta `SET SQL_SAFE_UPDATES = 0;` antes y `= 1` después. |
| Un conductor no recibe solicitudes | No está "conectado": su app debe estar abierta. Revisa `conductor.ultima_conexion`. |
| Viajes viejos colgados en `BUSCANDO_CONDUCTOR` | No se reintentan pasados 30 min. Para limpiarlos: `UPDATE viaje SET estado_viaje='CANCELADO' WHERE estado_viaje IN ('SOLICITADO','BUSCANDO_CONDUCTOR') AND fecha_solicitud < NOW() - INTERVAL 1 DAY;` |
| CORS desde Flutter web | Agrega `http://localhost:5000` a `cors.allowed-origins`. |
| 500 "No hay tarifa activa" | Falta la tarifa: la crea `TarifaSeeder` al arrancar con la BD vacía. |
| prediction-service responde 503 / `sin_modelo` | No hay artefactos: ejecuta `python entrenar.py` o reentrena desde la app. |
| "Se necesitan al menos N muestras" al entrenar | Faltan meses de historia: el modelo requiere unos 50 meses. |
| `pip install` de TensorFlow falla en Windows | Habilita las rutas largas (sección 3) y reinicia. |
