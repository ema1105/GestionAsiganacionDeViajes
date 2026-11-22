import 'package:flutter/foundation.dart';

import 'lugar_google.dart';
import 'ruta_calculada.dart';

/// Android/iOS: el SDK nativo lee la clave del AndroidManifest / AppDelegate.
/// Escritorio: sin soporte de google_maps_flutter.
Future<bool> cargarGoogleMaps(String apiKey) async =>
    defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

/// En móvil no llamamos a Directions/Routes REST (requeriría exponer la clave en otra API);
/// la pantalla usa la estimación por Haversine.
Future<RutaCalculada?> calcularRutaPorCalles(double oLat, double oLng, double dLat, double dLng) async => null;

/// La búsqueda de Google funciona en web; en móvil se usa el catálogo y el toque en el mapa.
void iniciarBusquedaLugares() {}

Future<List<SugerenciaLugar>> buscarLugares(String texto) async => const [];

Future<LugarGoogle?> detalleLugar(SugerenciaLugar sugerencia) async => null;

/// Sin geocodificación en móvil: el punto tocado se muestra como "Punto en el mapa".
Future<String?> direccionDe(double lat, double lng) async => null;