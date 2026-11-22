import '../../../core/json/json_read.dart';

/// Espejo de `PerfilConductorResponse`.
class PerfilConductor {
  const PerfilConductor({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.usuario,
    required this.email,
    required this.telefono,
    required this.disponible,
    this.licencia,
    this.marcaVehiculo,
    this.modeloVehiculo,
    this.placaVehiculo,
    this.capacidad = 0,
    this.categoriaVehiculo,
  });

  factory PerfilConductor.fromJson(Map<String, dynamic> j) => PerfilConductor(
        id: asInt(j['usuarioId']) ?? 0,
        nombre: asString(j['nombreCompleto']) ?? '',
        apellidos: asString(j['apellidosCompletos']) ?? '',
        usuario: asString(j['nombreUsuario']) ?? '',
        email: asString(j['email']) ?? '',
        telefono: asString(j['telefono']) ?? '',
        disponible: asBool(j['disponibilidad']),
        licencia: asString(j['tipoLicencia']),
        marcaVehiculo: asString(j['marcaVehiculo']),
        modeloVehiculo: asString(j['modeloVehiculo']),
        placaVehiculo: asString(j['placaVehiculo']),
        capacidad: asInt(j['capacidadMaxima']) ?? 0,
        categoriaVehiculo: asString(j['categoriaVehiculo']),
      );

  final int id;
  final String nombre;
  final String apellidos;
  final String usuario;
  final String email;
  final String telefono;
  final bool disponible;
  final String? licencia;
  final String? marcaVehiculo;
  final String? modeloVehiculo;
  final String? placaVehiculo;
  final int capacidad;
  final String? categoriaVehiculo;

  String get nombreCompleto => '$nombre $apellidos'.trim();
  bool get tieneVehiculo => (placaVehiculo ?? '').isNotEmpty;
  String get vehiculo => [marcaVehiculo, modeloVehiculo].whereType<String>().join(' ');
}

/// Espejo de `GananciasResponse` (total de viajes FINALIZADOS en el periodo).
class Ganancias {
  const Ganancias({required this.total, required this.viajes});

  factory Ganancias.fromJson(Map<String, dynamic> j) =>
      Ganancias(total: asDouble(j['total']) ?? 0, viajes: asInt(j['cantidadViajes']) ?? 0);

  final double total;
  final int viajes;
}

/// Espejo de `CalificacionResponse`.
class Calificacion {
  const Calificacion({
    required this.id,
    required this.puntuacion,
    required this.autor,
    this.comentario,
    this.fecha,
    this.viajeId,
  });

  factory Calificacion.fromJson(Map<String, dynamic> j) => Calificacion(
        id: reqInt(j['id'], 'id'),
        puntuacion: asInt(j['puntuacion']) ?? 0,
        autor: asString(j['calificadorNombre']) ?? 'Cliente',
        comentario: asString(j['comentario']),
        fecha: asServerDateTime(j['fechaCalificacion']),
        viajeId: asInt(j['viajeId']),
      );

  final int id;
  final int puntuacion;
  final String autor;
  final String? comentario;
  final DateTime? fecha;
  final int? viajeId;
}

/// Espejo de `PromedioCalificacionResponse`.
class PromedioCalificacion {
  const PromedioCalificacion({required this.promedio, required this.total});

  factory PromedioCalificacion.fromJson(Map<String, dynamic> j) => PromedioCalificacion(
        promedio: asDouble(j['promedio']),
        total: asInt(j['totalCalificaciones']) ?? 0,
      );

  /// null si aún no tiene calificaciones.
  final double? promedio;
  final int total;
}
