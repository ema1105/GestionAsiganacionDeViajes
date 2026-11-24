# GAV · App Flutter (Cliente, Conductor y Administrador)

Aplicación de **GAV – Gestión y Asignación de Viajes**, proyecto de aula de VIII semestre de Ingeniería de Sistemas (Fundación Universitaria Tecnológico Comfenalco, Cartagena). Cliente del proyecto: **Hotel Estelar Manzanillo del Mar**.

Una sola app Flutter (web, Android e iOS) con tres roles. Al iniciar sesión, el rol del JWT decide qué vista se abre:

| Rol | Qué hace |
|---|---|
| **Cliente** (huésped) | Solicita viajes en el mapa, ve al conductor en vivo, califica, consulta su historial y habla con el asistente. |
| **Conductor** | Recibe solicitudes (FIFO), avanza el viaje paso a paso, comparte su GPS, califica al cliente y ve ganancias y reseñas. |
| **Administrador** | Ve la predicción de demanda, la flota en vivo en el mapa, el histórico, gestiona conductores y vehículos, y reentrena el modelo predictivo. |

La app consume dos servicios:

- **Backend Spring Boot** (`/api/**`, autenticación JWT): rama `Backend` de este repositorio.
- **prediction-service** (FastAPI, red neuronal de demanda mensual): carpeta `prediction-service/` de la rama `Backend`. La app lo consume directo, sin pasar por Spring.

---

## Tabla de contenido

1. [Funcionalidades por rol](#1-funcionalidades-por-rol)
2. [Tecnologías](#2-tecnologías)
3. [Arquitectura](#3-arquitectura)
4. [Puesta en marcha](#4-puesta-en-marcha)
5. [Configuración (`env/*.json`)](#5-configuración-envjson)
6. [Mapas, rutas y GPS](#6-mapas-rutas-y-gps)
7. [Flujo de un viaje](#7-flujo-de-un-viaje)
8. [Asignación FIFO y conductores conectados](#8-asignación-fifo-y-conductores-conectados)
9. [Modelo predictivo desde la app](#9-modelo-predictivo-desde-la-app)
10. [Endpoints que consume la app](#10-endpoints-que-consume-la-app)
11. [Decisiones de integración](#11-decisiones-de-integración)
12. [Pruebas](#12-pruebas)
13. [Problemas frecuentes](#13-problemas-frecuentes)
14. [Limitaciones conocidas](#14-limitaciones-conocidas)

---

## 1. Funcionalidades por rol

### Cliente
- **Inicio:** viaje activo, número de viajes realizados, calificación propia y destinos más solicitados.
- **Solicitar viaje:**
  - Origen por GPS ("Usar mi ubicación actual"); se guarda el **nombre real de la calle o lugar** (geocodificación inversa), no "Mi ubicación".
  - Destino desde el catálogo de lugares de Cartagena, la búsqueda de Google Places o tocando el mapa.
  - Ruta **por calles** (Routes/Directions API), distancia, duración y precio cotizado por el backend antes de confirmar.
  - Conductores cercanos al origen.
- **Seguimiento en vivo:**
  - Posición del conductor cada 6 s, ruta real y tramo conductor → punto de recogida.
  - Distancia y tiempo de llegada por calles.
  - Al **finalizar** el viaje muestra el cierre y abre la calificación del conductor. Si el viaje se cancela, lo informa.
- **Mis viajes:** historial paginado con filtros y botón "Calificar" en los finalizados.
- **Asistente:** chatbot (Gemini, vía backend) con recomendaciones de lugares.
- **Perfil** y **notificaciones**.

### Conductor
- **Panel (Activo):**
  - Vehículo asignado y estado del GPS.
  - Solicitudes entrantes (aceptar o rechazar en 30 s).
  - Resumen del viaje activo.
- **Viaje:** detalle completo del viaje activo.
  - Datos y teléfono del cliente.
  - Mapa con ruta real y tramo hasta el cliente.
  - Valor, distancia y tiempo estimado.
  - Botones de acción: **Voy en camino → Iniciar viaje → Finalizar viaje**.
- **Calificar al cliente:** se abre al finalizar y también está disponible desde el Historial.
- **Historial**, **Ganancias** (día y mes), **Reseñas** (promedio y comentarios), **Perfil** y **notificaciones**.
- **GPS:** envía su ubicación cada 10 s mientras la sesión está abierta (`POST /api/conductor/ubicacion`) y, durante un viaje, los puntos de seguimiento que ve el cliente.

### Administrador
- **Inicio:** resumen del día, accesos a viajes, flota y dashboard (Power BI embebido).
- **Predicción:**
  - Demanda mensual estimada frente al mismo mes del año anterior, con gráficas y detalle por periodo.
  - **Modelo predictivo:** reentrenar la red neuronal desde la app, ver el progreso, comparar métricas (MAE, RMSE, MAPE) antes y después, y restaurar el modelo anterior.
- **Flota (en vivo):** mapa con los conductores **conectados**.
  - Verde = disponible; dorado = en viaje, con su ruta.
  - Contadores, filtros y lista.
  - Se actualiza cada 10 s. Solo aparecen conductores con sesión abierta y señal en los últimos 30 s; al cerrar sesión o ser deshabilitados, desaparecen.
- **Histórico:** comparación de predicciones por año.
- **Gestión:** conductores (registrar, habilitar o deshabilitar), vehículos, clientes y viajes con filtros por estado.
- **Perfil** y **notificaciones**.

---

## 2. Tecnologías

| Área | Paquete |
|---|---|
| Lenguaje / SDK | Flutter estable, **Dart ≥ 3.8** |
| Estado | `flutter_riverpod` 3 |
| Navegación | `go_router` 16 (`StatefulShellRoute` con barra inferior por rol) |
| HTTP | `dio` 5 (dos clientes: Spring y FastAPI) |
| Sesión | `flutter_secure_storage`, `jwt_decoder` |
| Mapas | `google_maps_flutter` + Maps JavaScript API en web (Routes/Directions, Places, Geocoding) |
| GPS | `geolocator` |
| UI | `material_ui`, `google_fonts` (Source Serif 4 + DM Sans), tema claro/oscuro propio |
| Otros | `intl`, `shared_preferences`, `url_launcher`, `webview_flutter`, `web` |
| Pruebas | `flutter_test`, `mocktail`, `http_mock_adapter` |

No se usa generación de código (freezed, riverpod_generator): basta con `flutter pub get`.

---

## 3. Arquitectura

Organización **por funcionalidad** (feature-first), con capas de Clean Architecture dentro de cada una.

```
lib/
├── main.dart                     ProviderScope + política de reintentos
├── app/                          MaterialApp.router, tema y router con protección por rol
├── core/
│   ├── config/env.dart           Variables de --dart-define-from-file
│   ├── network/                  Dio de Spring + AuthInterceptor (JWT), Dio de predicción, ApiPaths
│   ├── error/                    AppFailure (sealed) + guard(): DioException → AppFailure
│   ├── json/                     Lectores tolerantes (BigDecimal, LocalDateTime sin zona)
│   ├── pagination/               PageDto<T>, Pagina<T>, PaginatedState<T>
│   ├── storage/                  TokenStorage
│   ├── location/                 Permisos y posición GPS (geolocator)
│   ├── lugares/                  Catálogo de lugares de Cartagena y nombres de ruta legibles
│   ├── maps/                     GavMapa, carga de Maps JS, rutas por calles con caché, geocodificación
│   ├── theme/                    Colores y tipografías GAV (claro/oscuro)
│   ├── ui/ · widgets/            Componentes GAV (tarjetas, KPIs, chips, barra inferior) y AsyncValueView
└── features/
    ├── auth/                     Login, sesión persistida, rol desde el JWT
    ├── viajes_cliente/           Inicio, solicitar, seguimiento, historial, calificar, asistente, perfil
    ├── conductor/                Panel, Viaje, historial, ganancias, reseñas, rastreo GPS, calificar cliente
    ├── admin/                    Inicio, Flota en vivo, gestión, viajes, dashboard, perfil
    ├── prediccion/               Demanda mensual, detalle, histórico y entrenamiento del modelo
    └── notificaciones/           Bandeja de notificaciones (todos los roles)
```

Cada funcionalidad se divide en:

```
data/          DTOs + datasources (solo HTTP) + implementación del repositorio
domain/        Entidades + interfaz del repositorio (Dart puro)
presentation/  Providers de Riverpod + páginas + widgets
```

**Regla de dependencias:** `presentation → domain ← data`. La UI nunca importa Dio ni DTOs, y todos los errores llegan a ella como `AppFailure`.

---

## 4. Puesta en marcha

### Requisitos
- Flutter estable con Dart ≥ 3.8 (`flutter --version`; si es menor, `flutter upgrade`).
- Backend Spring Boot corriendo en `http://localhost:8080` (rama `Backend`).
- (Opcional) prediction-service en `http://localhost:8000`.
- Una clave de Google Maps con **Maps JavaScript API, Routes API (o Directions API), Places API (New) y Geocoding API** habilitadas.

### Pasos

```bash
# 1. Dependencias
flutter pub get

# 2. Configuración: copia la plantilla y pon tus valores (ver sección 5)
#    env/web.json para Chrome, env/dev.json para emulador Android

# 3. Ejecutar en Chrome (puerto fijo 5000, ya permitido en el CORS del backend)
flutter run -d chrome --web-port 5000 --dart-define-from-file=env/web.json

# Alternativa si Chrome no conecta el depurador (ver sección 13):
flutter run -d web-server --web-port 5000 --dart-define-from-file=env/web.json
#   y abre http://localhost:5000

# 4. Emulador Android
flutter run --dart-define-from-file=env/dev.json
```

En Windows, `setup.bat` hace la primera configuración (carpetas de plataforma, permisos de Android y dependencias).

### Ajustes de plataforma

**Android:** el backend en desarrollo usa HTTP.
- `android/app/src/main/AndroidManifest.xml`: `<uses-permission android:name="android.permission.INTERNET"/>` y los permisos de ubicación.
- `android/app/src/debug/AndroidManifest.xml`: `<application android:usesCleartextTraffic="true" />`.
- Clave de Maps en el `AndroidManifest.xml` (`com.google.android.geo.API_KEY`).

**iOS:** en `ios/Runner/Info.plist`, `NSAllowsLocalNetworking` y la descripción de uso de ubicación. La clave de Maps va en `AppDelegate`.

**Web:** el backend debe permitir el origen en `application.properties`:
```properties
cors.allowed-origins=http://localhost:5173,http://localhost:3000,http://localhost:5000
```

---

## 5. Configuración (`env/*.json`)

La app lee su configuración con `--dart-define-from-file`. Ejemplo de `env/web.json`:

```json
{
  "API_BASE_URL": "http://localhost:8080",
  "SERVER_OFFSET_HOURS": -5,
  "MAPS_API_KEY": "TU_CLAVE_DE_GOOGLE_MAPS",
  "PREDICCION_BASE_URL": "http://localhost:8000",
  "PREDICCION_API_KEY": ""
}
```

| Variable | Descripción |
|---|---|
| `API_BASE_URL` | Backend Spring. Chrome: `http://localhost:8080` · emulador Android: `http://10.0.2.2:8080` · celular físico: `http://<IP-LAN-del-PC>:8080`. |
| `SERVER_OFFSET_HOURS` | Zona en la que el backend genera sus `LocalDateTime`: `-5` en Colombia, `0` si la JVM corre en UTC (Docker o nube). |
| `MAPS_API_KEY` | Clave de Google Maps. Sin ella, la app funciona pero muestra un aviso en lugar del mapa. |
| `PREDICCION_BASE_URL` | prediction-service (FastAPI). Chrome: `http://localhost:8000` · emulador: `http://10.0.2.2:8000`. |
| `PREDICCION_API_KEY` | Vacía si el servicio no define `GAV_API_KEY`; si la define, se envía como `Authorization: Bearer <clave>`. |

> ⚠️ **No subas claves reales al repositorio.** Versiona solo plantillas (`env/web.example.json`, `env/dev.example.json`) con `"MAPS_API_KEY": "TU_CLAVE_DE_GOOGLE_MAPS"` y agrega los archivos reales al `.gitignore`:
> ```
> env/dev.json
> env/web.json
> env/*.local.json
> env/prod.json
> ```
> Además, restringe la clave en Google Cloud Console (por referente HTTP para web y por paquete o SHA-1 para Android).

---

## 6. Mapas, rutas y GPS

- **`GavMapa`** (`core/maps/gav_mapa.dart`) es el mapa común:
  - Marcadores de origen, destino y conductor, con estilo oscuro GAV.
  - Si no se le pasa una ruta, **calcula la ruta real por calles** y dibuja además el tramo **conductor → punto de recogida**.
  - Las rutas se guardan en **caché** (clave con coordenadas redondeadas) para no repetir llamadas a Google en cada ciclo del polling. El tramo del conductor se recalcula solo cuando se mueve unos 100 m.
- **Web:** usa la Maps JavaScript API (Routes API con respaldo a Directions, Places API New, Geocoder).
- **Android/iOS:** usa el SDK nativo. Las rutas por calles y la búsqueda de Google **solo están en web**; en móvil se muestra una línea recta y se estima con Haversine.
- **Nombres legibles:** primero se usa el catálogo de lugares; si no hay coincidencia, la dirección obtenida por geocodificación; y si tampoco hay, "Punto en el mapa".
- **GPS del conductor** (`features/conductor/presentation/controllers/rastreo_conductor.dart`):
  - Se activa al abrir el Panel y envía la posición al moverse y, como latido, **cada 10 s** aunque esté detenido.
  - Se detiene al cerrar sesión.
- **Precisión de coordenadas:** el backend guarda `DECIMAL(10,7)`. Con menos decimales, las posiciones se desplazan hasta ~1 km.

---

## 7. Flujo de un viaje

```
CLIENTE                         BACKEND                           CONDUCTOR
Solicitar viaje ──────────────► SOLICITADO → BUSCANDO_CONDUCTOR
                                FIFO ofrece al 1.º conectado ───► Solicitud entrante (30 s)
                                                    ◄──────────── Aceptar / Rechazar
Seguimiento (polling 6 s) ◄──── ACEPTADO
                                EN_CAMINO ◄────────────────────── "Voy en camino"
                                EN_CURSO  ◄────────────────────── "Iniciar viaje"
Cierre + calificar conductor ◄─ FINALIZADO ◄───────────────────── "Finalizar viaje" + calificar cliente
```

- El cliente puede cancelar mientras el viaje no haya iniciado (hasta `EN_CAMINO`).
- Las calificaciones van en las dos direcciones (`CLIENTE_A_CONDUCTOR` y `CONDUCTOR_A_CLIENTE`), una por viaje y dirección.

---

## 8. Asignación FIFO y conductores conectados

- El backend ofrece cada viaje al conductor **disponible, habilitado, con capacidad suficiente y conectado** que más tiempo lleva esperando (`fechaDisponibleDesde`).
- **Conectado** = la app dio señal en los últimos **30 s**. La señal sale del polling de solicitudes (cada 6 s) o del envío de GPS (cada 10 s). Los conductores con la app cerrada no reciben ofertas, así que no se pierden 30 s por cada uno.
- Si el conductor no responde en **30 s**, o cierra la app con una oferta pendiente, la oferta vence y pasa al siguiente.
- Si al pedir el viaje no hay nadie conectado, el viaje queda esperando y se asigna en cuanto alguien se conecte. Solo se reintentan viajes de los **últimos 30 minutos**.
- El revisor automático del backend corre **cada 5 s**.

---

## 9. Modelo predictivo desde la app

Ruta: **Admin → Predicción → Modelo predictivo** (`features/prediccion/presentation/pages/modelo_predictivo_page.dart`).

1. **Reentrenar modelo:** `POST /api/prediccion/reentrenar` responde al instante (202) y entrena en segundo plano con los viajes **FINALIZADOS y CANCELADOS**, agrupados por mes.
2. La pantalla consulta `GET /api/prediccion/reentrenar/estado` cada 3 s y muestra el paso actual y el log.
3. Al terminar, compara las métricas **antes y ahora** (MAE, RMSE, MAPE) y recomienda conservar o restaurar.
4. **Restaurar modelo anterior:** `POST /api/prediccion/modelo/restaurar`. Antes de cada entrenamiento se respalda el modelo; si el entrenamiento falla, se conserva el anterior.

Mientras entrena, las predicciones siguen usando el modelo vigente. El modelo necesita unos 50 meses de historia; con menos datos, el entrenamiento falla con un mensaje claro y no reemplaza el modelo vigente.

---

## 10. Endpoints que consume la app

Todas las rutas del backend Spring están centralizadas en `core/network/api_paths.dart`.

**Autenticación:** `POST /api/auth/login`, `POST /api/auth/register/cliente`

**Cliente** (`/api/cliente`):
- Viajes: `POST /viajes`, `GET /viajes/cotizar`, `GET /viaje-activo`, `GET /viajes`, `GET /viajes/{id}`, `POST /viajes/{id}/cancelar`
- Seguimiento: `GET /viajes/{id}/seguimiento/ultima`
- Calificaciones: `POST /viajes/{id}/calificar`, `GET /calificaciones/promedio`
- Otros: `GET /conductores-cercanos`, `GET /lugares/mas-solicitados`, `POST /chatbot/mensaje`, `GET|PUT /perfil`

**Conductor** (`/api/conductor`):
- Solicitudes: `GET /solicitudes/pendiente`, `POST /viajes/{id}/responder`
- Viaje activo: `GET /viaje-activo`, `GET /viajes/{id}/detalle`
- Estados del viaje: `POST /viajes/{id}/en-camino`, `POST /viajes/{id}/iniciar`, `POST /viajes/{id}/finalizar`
- Calificaciones: `POST /viajes/{id}/calificar-cliente`, `GET /calificaciones`, `GET /calificaciones/promedio`
- GPS: `POST /ubicacion`, `POST /viajes/{id}/seguimiento`
- Otros: `GET /viajes`, `GET /estadisticas/ganancias/dia|mes`, `GET|PUT /perfil`

**Administrador** (`/api/admin`):
- Flota: `GET /flota/ubicaciones`, `GET|POST /conductores`, `POST /conductores/{id}/deshabilitar|habilitar`
- Catálogos: `GET /vehiculos`, `GET /clientes`, `GET /categorias`
- Viajes y estadísticas: `GET /viajes`, `GET /estadisticas/…`
- Otros: `GET /dashboard/url`, `GET|PUT /perfil`

**Notificaciones:** `GET /api/notificaciones/mias`, `GET /api/notificaciones/no-leidas/count`, `POST /api/notificaciones/{id}/leer`, `POST /api/notificaciones/leer-todas`

**prediction-service** (FastAPI):
- Predicción: `GET /api/prediccion/mensual`, `GET /api/prediccion/modelo`, `GET /api/prediccion/salud`
- Entrenamiento: `POST /api/prediccion/reentrenar`, `GET /api/prediccion/reentrenar/estado`, `POST /api/prediccion/modelo/restaurar`

---

## 11. Decisiones de integración

- **401 y 403:** un 401 fuera de `/api/auth` limpia el token y manda al login. Un 403 no cierra la sesión. Un 401 en el login significa credenciales inválidas o cuenta deshabilitada.
- **Sin refresh token:** el JWT dura 24 h y se valida `exp` antes de cada petición. `AuthInterceptor` ya es `QueuedInterceptor`, listo para un futuro `/api/auth/refresh`.
- **204 No Content:** `viaje-activo`, `seguimiento/ultima` y `solicitudes/pendiente` devuelven `null`, no un error.
- **Paginación:** la página empieza en 0. `PageDto` acepta `last` o `isLast`, quita ids duplicados y se reinicia al cambiar el filtro.
- **Polling** (6 s en viajes y solicitudes, 10 s en la flota) detrás de un `Stream`. Se cancela al salir de la pantalla (`autoDispose`). Pasar a WebSocket/STOMP solo cambiaría el repositorio.
- **Reintentos:** solo para errores de red, timeout y 5xx (`ProviderScope.retry`). Nunca para 4xx.
- **Errores de FastAPI:** `{"detail": …}` se traduce a `AppFailure` aparte (`prediccion_errores.dart`), porque su formato es distinto al de Spring.

---

## 12. Pruebas

```bash
flutter analyze
flutter test
```

Hay pruebas del mapeo de errores (`guard`), de los lectores JSON y de los DTOs y errores del servicio de predicción (`test/`).

---

## 13. Problemas frecuentes

| Síntoma | Causa / solución |
|---|---|
| `AppConnectionException` / "Failed to establish connection with the application instance in Chrome" | La app compiló, pero falló el canal de depuración (firewall, antivirus u otro Chrome abierto). Usa `flutter run -d web-server --web-port 5000 …` y abre `http://localhost:5000`. También ayuda cerrar Chrome, permitir `dart.exe` en el firewall o correr `flutter clean`. |
| El mapa dice "Configura MAPS_API_KEY" | Falta la clave en `env/*.json` o no ejecutaste con `--dart-define-from-file`. |
| La ruta sale como línea recta | Estás en Android/iOS (rutas por calles solo en web), o la clave no tiene habilitada Routes API ni Directions API. |
| Error de CORS en Chrome | Agrega `http://localhost:5000` a `cors.allowed-origins` del backend. |
| Distancias de "0,0 km" o marcadores corridos | Las columnas de coordenadas de la BD tienen menos de 7 decimales: deben ser `DECIMAL(10,7)`. |
| Un conductor no recibe solicitudes o no aparece en Flota | No está "conectado": debe tener la app abierta con el GPS permitido. En segundo plano, el navegador frena los envíos. |
| La predicción responde 503 o "sin modelo" | El prediction-service no tiene un modelo entrenado: entrénalo desde Admin → Predicción → Modelo predictivo, o con `python entrenar.py`. |

---

## 14. Limitaciones conocidas

- **Sin servicio en segundo plano** en móvil: si el conductor minimiza la app, deja de enviar GPS y se considera desconectado.
- **Rutas por calles y búsqueda de Google** solo en web.
- **Polling** en lugar de WebSocket: el retraso máximo es de unos 10–20 s.
- La ubicación del conductor es un dato personal (Ley 1581 de 2012): solo se muestra mientras tiene la sesión abierta. Los conductores deben ser informados de que se registra su ubicación durante la jornada.
