import 'package:geolocator/geolocator.dart';

/// Resultado de pedir permiso de ubicación.
enum EstadoPermiso {
  concedido,
  denegado,
  denegadoPermanente,
  servicioApagado,
  noDisponible;

  bool get ok => this == concedido;

  String get mensaje => switch (this) {
        concedido => 'Ubicación activa',
        denegado => 'Permiso de ubicación denegado. Tócalo para volver a intentarlo.',
        denegadoPermanente => 'Permiso bloqueado. Actívalo en la configuración del navegador o del teléfono.',
        servicioApagado => 'El GPS del dispositivo está apagado.',
        noDisponible => 'No se pudo obtener la ubicación en este dispositivo.',
      };
}

/// Acceso al GPS (Android, iOS y navegador) con manejo de permisos.
abstract final class Ubicacion {
  static const _ajustes = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 20);

  /// Pide permiso si hace falta. En web dispara el aviso del navegador.
  static Future<EstadoPermiso> solicitarPermiso() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return EstadoPermiso.servicioApagado;
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      return switch (permiso) {
        LocationPermission.always || LocationPermission.whileInUse => EstadoPermiso.concedido,
        LocationPermission.denied => EstadoPermiso.denegado,
        LocationPermission.deniedForever => EstadoPermiso.denegadoPermanente,
        LocationPermission.unableToDetermine => EstadoPermiso.noDisponible,
      };
    } catch (_) {
      return EstadoPermiso.noDisponible;
    }
  }

  /// Posición actual (pide permiso primero). null si no se pudo.
  static Future<Position?> actual() async {
    if (!(await solicitarPermiso()).ok) return null;
    try {
      return await Geolocator.getCurrentPosition(locationSettings: _ajustes)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return Geolocator.getLastKnownPosition().catchError((_) => null);
    }
  }

  /// Flujo de posiciones (cada ~20 m de movimiento).
  static Stream<Position> seguir() => Geolocator.getPositionStream(locationSettings: _ajustes);
}
