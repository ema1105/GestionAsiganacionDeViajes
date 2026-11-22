import 'estado_viaje.dart';

class Coordenada {
  const Coordenada(this.lat, this.lng);
  final double lat;
  final double lng;

  @override
  String toString() => '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}

/// Entidad de dominio: lo que la UI necesita, sin detalles de JSON.
class Viaje {
  const Viaje({
    required this.id,
    required this.cantidadPasajeros,
    required this.origen,
    required this.destino,
    required this.estado,
    this.clienteNombre,
    this.conductorNombre,
    this.precio,
    this.solicitadoEn,
    this.iniciadoEn,
    this.finalizadoEn,
    this.origenNombre,
    this.destinoNombre,
  });

  final int id;
  final int cantidadPasajeros;
  final Coordenada origen;
  final Coordenada destino;
  final EstadoViaje estado;
  final String? clienteNombre;

  /// null mientras el viaje está buscando conductor.
  final String? conductorNombre;
  final double? precio;
  final DateTime? solicitadoEn;
  final DateTime? iniciadoEn;
  final DateTime? finalizadoEn;

  /// Nombre legible guardado al solicitar ("Hospital Bocagrande"). null en viajes antiguos.
  final String? origenNombre;
  final String? destinoNombre;

  bool get tieneConductor => conductorNombre != null && conductorNombre!.isNotEmpty;
}

class PuntoSeguimiento {
  const PuntoSeguimiento({required this.posicion, this.fecha});
  final Coordenada posicion;
  final DateTime? fecha;
}

/// Filtros del historial. Implementa ==/hashCode porque es la clave del provider family.
class FiltroViajes {
  const FiltroViajes({this.estado, this.desde, this.hasta});

  final EstadoViaje? estado;
  final DateTime? desde;
  final DateTime? hasta;

  @override
  bool operator ==(Object other) =>
      other is FiltroViajes &&
      other.estado == estado &&
      other.desde == desde &&
      other.hasta == hasta;

  @override
  int get hashCode => Object.hash(estado, desde, hasta);
}