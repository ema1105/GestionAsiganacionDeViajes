/// Configuración por entorno inyectada con `--dart-define-from-file=env/<x>.json`.
///
/// - Emulador Android: `http://10.0.2.2:8080` (localhost del PC).
/// - Dispositivo físico: IP LAN del PC, p. ej. `http://192.168.1.20:8080`.
/// - Flutter Web: `http://localhost:8080` (y agregar el origen a `cors.allowed-origins`).
abstract final class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Offset (horas) de la zona en la que el backend genera sus `LocalDateTime`.
  /// Colombia = -5. Si el backend corre en Docker/nube con JVM en UTC, usar 0.
  static const int serverOffsetHours = int.fromEnvironment(
    'SERVER_OFFSET_HOURS',
    defaultValue: -5,
  );

  /// Misma clave de Google Maps que usa el frontend React (VITE_GOOGLE_MAPS_API_KEY).
  /// Necesita habilitadas: Maps JavaScript API y Directions API (web) /
  /// Maps SDK for Android (Android).
  static const String mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  /// Servicio de predicción (FastAPI). Se consume directo, sin pasar por Spring.
  /// - Emulador Android: `http://10.0.2.2:8000`.
  /// - Flutter Web: `http://localhost:8000`.
  static const String prediccionBaseUrl = String.fromEnvironment(
    'PREDICCION_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Clave opcional del servicio (`GAV_API_KEY` en su `.env`). Vacía = servicio abierto.
  static const String prediccionApiKey = String.fromEnvironment('PREDICCION_API_KEY');

  /// Algunos meses pasados se calculan al vuelo; se da margen extra.
  static const Duration prediccionTimeout = Duration(seconds: 30);

  static bool get tieneMapa => mapsApiKey.isNotEmpty && !mapsApiKey.startsWith('PEGA_AQUI');

  /// Cada cuánto el conductor reporta su posición al backend.
  static const Duration intervaloUbicacion = Duration(seconds: 10);

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// El chatbot (Gemini) tiene 15 s de timeout en el backend: el cliente debe esperar más.
  static const Duration chatbotTimeout = Duration(seconds: 30);

  /// Intervalo de polling mientras no exista WebSocket/STOMP en el backend.
  static const Duration pollingInterval = Duration(seconds: 6);

  /// Presentación: `DEMO_MODE=true` responde la predicción desde assets/demo/ sin red.
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE');

  /// Si la nube no responde, la predicción usa el respaldo de assets/demo/.
  static const bool fallbackDemo = bool.fromEnvironment('FALLBACK_DEMO', defaultValue: true);
}
