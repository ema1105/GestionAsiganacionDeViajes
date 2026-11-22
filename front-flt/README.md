# GAV App (Flutter): Cliente y Conductor

App móvil de **GAV, Gestión y Asignación de Viajes**. Consume el backend Spring Boot (`/api/**`, JWT).
Por ahora, Admin y Recepcionista siguen en el panel web (React).

## Arquitectura

Organización por funcionalidad (feature-first) con capas de Clean Architecture dentro de cada una:

```
lib/
├── main.dart                 ProviderScope + política de reintentos
├── app/                      MaterialApp.router, tema, router por rol (go_router)
├── core/
│   ├── config/env.dart       URL del backend y offset de zona (--dart-define-from-file)
│   ├── network/              Dio, AuthInterceptor (JWT), ApiPaths
│   ├── error/                AppFailure (sealed) + guard() (DioException → AppFailure)
│   ├── json/                 lectores tolerantes (BigDecimal, LocalDateTime sin zona)
│   ├── pagination/           PageDto<T> (espejo de PageResponse), Pagina<T>, PaginatedState<T>
│   ├── storage/              TokenStorage (flutter_secure_storage)
│   └── widgets/              AsyncValueView: carga / error / vacío / datos
└── features/
    ├── auth/                 login, sesión persistida, rol desde el JWT
    ├── viajes_cliente/       viaje activo, cancelar, historial paginado, seguimiento
    ├── conductor/            solicitud pendiente (aceptar/rechazar), avanzar estado del viaje
    └── prediccion/           demanda mensual (FastAPI): Dio propio, errores `detail` → AppFailure
        ├── data/             DTOs + datasources (solo HTTP) + repositorio impl
        ├── domain/           entidades + interfaz del repositorio (Dart puro)
        └── presentation/     providers (Riverpod 3) + páginas
```

**Regla:** `presentation → domain ← data`. La UI nunca importa Dio ni DTOs.
Todos los errores llegan a la UI como `AppFailure`.

> El esqueleto no usa generación de código (freezed/riverpod_generator) para que funcione
> con solo `flutter pub get`. Se puede migrar más adelante sin tocar la UI.

## Puesta en marcha

Requisitos: Flutter estable con **Dart ≥ 3.8** (`flutter --version`; si es menor, `flutter upgrade`).

```bash
# 1. Generar las carpetas de plataforma (NO sobrescribe lib/, test/ ni pubspec.yaml)
flutter create . --project-name gav_app --org com.gav --platforms android,ios,web

# 2. Dependencias
flutter pub get

# 3. Tests (mapeo de errores, JSON, estados de UI)
flutter test

# 4. Ejecutar (o F5 en VS Code con "GAV (dev)")
flutter run --dart-define-from-file=env/dev.json
```

### Ajustes de plataforma después de `flutter create`

**Android:** el backend en dev usa HTTP.
- En `android/app/src/main/AndroidManifest.xml`, antes de `<application>`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```
- En `android/app/src/debug/AndroidManifest.xml`, solo para debug:
  ```xml
  <application android:usesCleartextTraffic="true" />
  ```

**iOS:** en `ios/Runner/Info.plist`, para desarrollo:
```xml
<key>NSAppTransportSecurity</key>
<dict><key>NSAllowsLocalNetworking</key><true/></dict>
```

**Flutter Web:** se ejecuta en el puerto fijo 5000 (`env/web.json`). Agrega ese origen al backend
(`application.properties`):
```properties
cors.allowed-origins=http://localhost:5173,http://localhost:3000,http://localhost:5000
```

### ¿A qué URL apunta?
| Dónde corre la app | `API_BASE_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:8080` (por defecto, `env/dev.json`) |
| Celular físico (misma WiFi) | `http://<IP-LAN-del-PC>:8080` (crear `env/dev.local.json`) |
| Chrome (web) | `http://localhost:8080` (`env/web.json`) |

**Servicio de predicción (FastAPI, `prediction-service`).** Se consume directo, sin pasar por Spring:

| Dónde corre la app | `PREDICCION_BASE_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:8000` (`env/dev.json`) |
| Chrome (web) | `http://localhost:8000` (`env/web.json`) |

`PREDICCION_API_KEY` va vacía mientras el servicio no defina `GAV_API_KEY`; si la definen, se envía como
`Authorization: Bearer <clave>`.

`SERVER_OFFSET_HOURS`: zona en la que el backend genera sus `LocalDateTime`. Es `-5` en Colombia
y `0` si el backend corre en Docker o en la nube con la JVM en UTC.

## Decisiones clave de integración

- **401 y 403:** un 401 fuera de `/api/auth` limpia el token y manda al login. Un 403 no cierra la
  sesión. Un 401 en el login significa credenciales inválidas o cuenta deshabilitada.
- **Sin refresh token:** el JWT dura 24 h. Se valida `exp` antes de cada petición.
  `AuthInterceptor` es `QueuedInterceptor`, listo para cuando exista `/api/auth/refresh`.
- **204 No Content:** `viaje-activo`, `seguimiento/ultima` y `solicitudes/pendiente` devuelven `null`, no un error.
- **Paginación:** la página empieza en 0. `PageDto` acepta `last` o `isLast`, quita ids duplicados y se
  reinicia al cambiar el filtro.
- **Polling cada 6 s** detrás de un `Stream`. Se cancela al salir de la pantalla (`autoDispose`).
  El paso a WebSocket/STOMP solo cambia el repositorio.
- **Reintentos:** solo para errores de red, timeout y 5xx (`ProviderScope.retry`). Nunca para 4xx.

## Hoja de ruta

- [x] **Fase 1–3:** núcleo de red, errores, auth, router por rol
- [x] Cliente: viaje activo, cancelar, historial paginado con filtros, seguimiento (polling)
- [x] Conductor: solicitud pendiente (aceptar/rechazar), en camino → iniciar → finalizar
- [ ] **Fase 4:** solicitar viaje con `google_maps_flutter` + Directions/Routes API (`distanciaKm`, `duracionMin`) y conductores cercanos en el mapa
- [ ] **Fase 5:** heartbeat GPS del conductor (`geolocator`, permisos, servicio en primer plano) → `POST /api/conductor/ubicacion`
- [ ] Calificaciones (cliente ↔ conductor), perfil, ganancias del conductor
- [ ] Notificaciones (contador de no leídas, luego FCM o WebSocket)
- [ ] Chatbot (`/api/cliente/chatbot/mensaje`, timeout de 30 s)
- [ ] Registro de cliente
- [x] Admin · Predicción (04), Detalle del periodo (05) e Histórico predicción vs. real (06) con `prediction-service`
