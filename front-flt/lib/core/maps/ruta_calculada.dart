import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Ruta por calles devuelta por Directions (distancia, duración y trazado).
class RutaCalculada {
  const RutaCalculada({required this.km, required this.minutos, required this.puntos});
  final double km;
  final int minutos;
  final List<LatLng> puntos;
}

/// Decodifica una "encoded polyline" de Google.
List<LatLng> decodificarPolyline(String encoded) {
  final puntos = <LatLng>[];
  var index = 0, lat = 0, lng = 0;
  while (index < encoded.length) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    puntos.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return puntos;
}
