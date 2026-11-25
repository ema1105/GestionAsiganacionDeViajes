import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'lugar_google.dart';
import 'ruta_calculada.dart';

/// Android/iOS: el SDK nativo lee la clave del AndroidManifest / AppDelegate.
/// Escritorio: sin soporte de google_maps_flutter.
Future<bool> cargarGoogleMaps(String apiKey) async =>
    defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

final Dio _dioRutas = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
    contentType: Headers.jsonContentType,
  ),
);

/// Ruta por calles en móvil con las APIs REST de Google y la misma MAPS_API_KEY.
/// Mismo orden que en web: Routes API y, si no está habilitada, Directions API.
/// null si ninguna responde: la pantalla vuelve a la estimación por Haversine.
Future<RutaCalculada?> calcularRutaPorCalles(double oLat, double oLng, double dLat, double dLng) async {
  if (!Env.tieneMapa) return null;
  return await _rutaConRoutesApi(oLat, oLng, dLat, dLng) ??
      await _rutaConDirections(oLat, oLng, dLat, dLng);
}

RutaCalculada _ruta(double metros, double segundos, String polyline) => RutaCalculada(
      km: double.parse((metros / 1000).toStringAsFixed(2)),
      minutos: (segundos / 60).ceil(),
      puntos: decodificarPolyline(polyline),
    );

Map<String, Object> _punto(double lat, double lng) => {
      'location': {
        'latLng': {'latitude': lat, 'longitude': lng},
      },
    };

/// Routes API (computeRoutes). Requiere "Routes API" habilitada para la clave.
Future<RutaCalculada?> _rutaConRoutesApi(double oLat, double oLng, double dLat, double dLng) async {
  try {
    final res = await _dioRutas.post<Map<String, dynamic>>(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
      options: Options(
        headers: {
          'X-Goog-Api-Key': Env.mapsApiKey,
          'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
        },
      ),
      data: {
        'origin': _punto(oLat, oLng),
        'destination': _punto(dLat, dLng),
        'travelMode': 'DRIVE',
        'languageCode': 'es-419',
        'units': 'METRIC',
      },
    );
    final routes = (res.data?['routes'] as List<dynamic>?) ?? const [];
    if (routes.isEmpty) return null;
    final ruta = routes.first as Map<String, dynamic>;
    final metros = (ruta['distanceMeters'] as num?)?.toDouble();
    final duracion = ruta['duration'] as String?; // p. ej. "1534s"
    final polyline = (ruta['polyline'] as Map<String, dynamic>?)?['encodedPolyline'] as String?;
    if (metros == null || duracion == null || polyline == null) return null;
    final segundos = double.tryParse(duracion.replaceAll('s', '')) ?? 0;
    return _ruta(metros, segundos, polyline);
  } catch (e) {
    if (kDebugMode) debugPrint('Routes API no disponible: $e');
    return null;
  }
}

/// Directions API (legacy), igual que DirectionsService en web.
Future<RutaCalculada?> _rutaConDirections(double oLat, double oLng, double dLat, double dLng) async {
  try {
    final res = await _dioRutas.get<Map<String, dynamic>>(
      'https://maps.googleapis.com/maps/api/directions/json',
      queryParameters: {
        'origin': '$oLat,$oLng',
        'destination': '$dLat,$dLng',
        'mode': 'driving',
        'language': 'es',
        'key': Env.mapsApiKey,
      },
    );
    final data = res.data;
    if (data == null || data['status'] != 'OK') {
      if (kDebugMode) debugPrint('Directions API: ${data?['status']} ${data?['error_message'] ?? ''}');
      return null;
    }
    final routes = data['routes'] as List<dynamic>;
    if (routes.isEmpty) return null;
    final ruta = routes.first as Map<String, dynamic>;
    final legs = ruta['legs'] as List<dynamic>;
    if (legs.isEmpty) return null;
    final leg = legs.first as Map<String, dynamic>;
    final metros = ((leg['distance'] as Map<String, dynamic>)['value'] as num).toDouble();
    final segundos = ((leg['duration'] as Map<String, dynamic>)['value'] as num).toDouble();
    final polyline = (ruta['overview_polyline'] as Map<String, dynamic>)['points'] as String;
    return _ruta(metros, segundos, polyline);
  } catch (e) {
    if (kDebugMode) debugPrint('Directions API no disponible: $e');
    return null;
  }
}

/// La búsqueda de Google funciona en web; en móvil se usa el catálogo y el toque en el mapa.
void iniciarBusquedaLugares() {}

Future<List<SugerenciaLugar>> buscarLugares(String texto) async => const [];

Future<LugarGoogle?> detalleLugar(SugerenciaLugar sugerencia) async => null;

/// Sin geocodificación en móvil: el punto tocado se muestra como "Punto en el mapa".
Future<String?> direccionDe(double lat, double lng) async => null;
