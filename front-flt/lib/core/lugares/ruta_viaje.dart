import '../../features/viajes_cliente/domain/entities/viaje.dart';
import 'lugares.dart';

/// Ruta legible para tarjetas y listas: "Hotel Las Américas → Aeropuerto".
/// Por cada extremo usa, en orden: el nombre corto del catálogo si la coordenada cae
/// en un lugar conocido, el nombre guardado al solicitar (búsqueda o mapa) y,
/// si no hay ninguno, "Punto en el mapa".
String rutaDe(Coordenada origen, Coordenada destino, {String? origenNombre, String? destinoNombre}) {
  final a = Lugares.cercano(origen.lat, origen.lng)?.corto ?? _limpio(origenNombre);
  final b = Lugares.cercano(destino.lat, destino.lng)?.corto ?? _limpio(destinoNombre);
  if (a == null && b == null) return 'Origen → Destino';
  return '${a ?? 'Punto en el mapa'} → ${b ?? 'Punto en el mapa'}';
}

String? _limpio(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

extension RutaViajeX on Viaje {
  String get ruta => rutaDe(origen, destino, origenNombre: origenNombre, destinoNombre: destinoNombre);
}