import '../../../../core/json/json_read.dart';
import '../../domain/entities/estado_viaje.dart';
import '../../domain/entities/viaje.dart';

/// Espejo de `ViajeResponse` (Spring). Si el contrato cambia, solo cambia este archivo.
class ViajeDto {
  const ViajeDto({
    required this.id,
    required this.cantidadPasajeros,
    required this.origenLat,
    required this.origenLng,
    required this.destinoLat,
    required this.destinoLng,
    required this.estadoViaje,
    this.clienteId,
    this.clienteNombre,
    this.conductorId,
    this.conductorNombre,
    this.precioCalculado,
    this.fechaSolicitud,
    this.fechaInicio,
    this.fechaFinalizacion,
    this.origenNombre,
    this.destinoNombre,
  });

  factory ViajeDto.fromJson(Map<String, dynamic> j) => ViajeDto(
        id: reqInt(j['id'], 'id'),
        cantidadPasajeros: asInt(j['cantidadPasajeros']) ?? 1,
        origenLat: reqDouble(j['origenLat'], 'origenLat'),
        origenLng: reqDouble(j['origenLng'], 'origenLng'),
        destinoLat: reqDouble(j['destinoLat'], 'destinoLat'),
        destinoLng: reqDouble(j['destinoLng'], 'destinoLng'),
        estadoViaje: EstadoViaje.fromApi(asString(j['estadoViaje'])),
        clienteId: asInt(j['clienteId']),
        clienteNombre: asString(j['clienteNombre']),
        conductorId: asInt(j['conductorId']),
        conductorNombre: asString(j['conductorNombre']),
        precioCalculado: asDouble(j['precioCalculado']),
        fechaSolicitud: asServerDateTime(j['fechaSolicitud']),
        fechaInicio: asServerDateTime(j['fechaInicio']),
        fechaFinalizacion: asServerDateTime(j['fechaFinalizacion']),
        origenNombre: asString(j['origenNombre']),
        destinoNombre: asString(j['destinoNombre']),
      );

  final int id;
  final int cantidadPasajeros;
  final double origenLat;
  final double origenLng;
  final double destinoLat;
  final double destinoLng;
  final EstadoViaje estadoViaje;
  final int? clienteId;
  final String? clienteNombre;
  final int? conductorId;
  final String? conductorNombre;
  final double? precioCalculado;
  final DateTime? fechaSolicitud;
  final DateTime? fechaInicio;
  final DateTime? fechaFinalizacion;
  final String? origenNombre;
  final String? destinoNombre;

  Viaje toEntity() => Viaje(
        id: id,
        cantidadPasajeros: cantidadPasajeros,
        origen: Coordenada(origenLat, origenLng),
        destino: Coordenada(destinoLat, destinoLng),
        estado: estadoViaje,
        clienteNombre: clienteNombre,
        conductorNombre: conductorNombre,
        precio: precioCalculado,
        solicitadoEn: fechaSolicitud,
        iniciadoEn: fechaInicio,
        finalizadoEn: fechaFinalizacion,
        origenNombre: origenNombre,
        destinoNombre: destinoNombre,
      );
}

/// Espejo de `PuntoSeguimientoResponse`.
class PuntoSeguimientoDto {
  const PuntoSeguimientoDto({required this.lat, required this.lng, this.fecha});

  factory PuntoSeguimientoDto.fromJson(Map<String, dynamic> j) => PuntoSeguimientoDto(
        lat: reqDouble(j['lat'], 'lat'),
        lng: reqDouble(j['lng'], 'lng'),
        fecha: asServerDateTime(j['fecha']),
      );

  final double lat;
  final double lng;
  final DateTime? fecha;

  PuntoSeguimiento toEntity() => PuntoSeguimiento(posicion: Coordenada(lat, lng), fecha: fecha);
}