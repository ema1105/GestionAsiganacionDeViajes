import '../../../../core/json/json_read.dart';
import '../../../viajes_cliente/domain/entities/viaje.dart';
import '../../domain/solicitud_pendiente.dart';

/// Espejo de `SolicitudPendienteDTO` (GET /api/conductor/solicitudes/pendiente).
class SolicitudPendienteDto {
  const SolicitudPendienteDto({
    required this.solicitudId,
    required this.viajeId,
    required this.cantidadPasajeros,
    required this.origenLat,
    required this.origenLng,
    required this.destinoLat,
    required this.destinoLng,
    this.estado,
    this.clienteNombre,
    this.precioCalculado,
    this.fechaOferta,
    this.fechaExpiracion,
    this.origenNombre,
    this.destinoNombre,
  });

  factory SolicitudPendienteDto.fromJson(Map<String, dynamic> j) => SolicitudPendienteDto(
        solicitudId: reqInt(j['solicitudId'], 'solicitudId'),
        viajeId: reqInt(j['viajeId'], 'viajeId'),
        cantidadPasajeros: asInt(j['cantidadPasajeros']) ?? 1,
        origenLat: reqDouble(j['origenLat'], 'origenLat'),
        origenLng: reqDouble(j['origenLng'], 'origenLng'),
        destinoLat: reqDouble(j['destinoLat'], 'destinoLat'),
        destinoLng: reqDouble(j['destinoLng'], 'destinoLng'),
        estado: asString(j['estado']),
        clienteNombre: asString(j['clienteNombre']),
        precioCalculado: asDouble(j['precioCalculado']),
        fechaOferta: asServerDateTime(j['fechaOferta']),
        fechaExpiracion: asServerDateTime(j['fechaExpiracion']),
        origenNombre: asString(j['origenNombre']),
        destinoNombre: asString(j['destinoNombre']),
      );

  final int solicitudId;
  final int viajeId;
  final int cantidadPasajeros;
  final double origenLat;
  final double origenLng;
  final double destinoLat;
  final double destinoLng;
  final String? estado;
  final String? clienteNombre;
  final double? precioCalculado;
  final DateTime? fechaOferta;
  final DateTime? fechaExpiracion;
  final String? origenNombre;
  final String? destinoNombre;

  SolicitudPendiente toEntity() => SolicitudPendiente(
        solicitudId: solicitudId,
        viajeId: viajeId,
        cantidadPasajeros: cantidadPasajeros,
        origen: Coordenada(origenLat, origenLng),
        destino: Coordenada(destinoLat, destinoLng),
        clienteNombre: clienteNombre,
        precio: precioCalculado,
        expiraEn: fechaExpiracion,
        origenNombre: origenNombre,
        destinoNombre: destinoNombre,
      );
}