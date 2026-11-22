import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/error/guard.dart';
import '../../../core/json/json_read.dart';
import '../../../core/lugares/lugares.dart';
import '../../../core/network/dio_provider.dart';
import '../../conductor/domain/conductor_models.dart';
import '../domain/entities/viaje.dart';
import 'dtos/viaje_dto.dart';

/// Espejo de `PerfilClienteResponse`.
class PerfilCliente {
  const PerfilCliente({
    required this.nombre,
    required this.apellidos,
    required this.usuario,
    required this.email,
    required this.telefono,
    this.documento,
  });

  factory PerfilCliente.fromJson(Map<String, dynamic> j) => PerfilCliente(
        nombre: asString(j['nombreCompleto']) ?? '',
        apellidos: asString(j['apellidosCompletos']) ?? '',
        usuario: asString(j['nombreUsuario']) ?? '',
        email: asString(j['email']) ?? '',
        telefono: asString(j['telefono']) ?? '',
        documento: [asString(j['tipoDocumento']), asString(j['numeroDocumento'])].whereType<String>().join(' '),
      );

  final String nombre;
  final String apellidos;
  final String usuario;
  final String email;
  final String telefono;
  final String? documento;

  String get nombreCompleto => '$nombre $apellidos'.trim();
}

/// Conductor disponible cerca del origen (`ConductorCercanoResponse`).
class ConductorCercano {
  const ConductorCercano({required this.nombre, required this.distanciaKm, this.vehiculo});

  factory ConductorCercano.fromJson(Map<String, dynamic> j) => ConductorCercano(
        nombre: asString(j['nombreCompleto']) ?? '',
        distanciaKm: asDouble(j['distanciaKm']) ?? 0,
        vehiculo: [asString(j['vehiculoMarca']), asString(j['vehiculoModelo'])].whereType<String>().join(' '),
      );

  final String nombre;
  final double distanciaKm;
  final String? vehiculo;
}

/// Lugar popular (`LugarPopularResponse`).
class LugarPopular {
  const LugarPopular({required this.nombre, required this.categoria, required this.totalViajes});

  factory LugarPopular.fromJson(Map<String, dynamic> j) => LugarPopular(
        nombre: asString(j['nombre']) ?? '',
        categoria: asString(j['categoria']) ?? '',
        totalViajes: asInt(j['totalViajes']) ?? 0,
      );

  final String nombre;
  final String categoria;
  final int totalViajes;
}

class RespuestaChatbot {
  const RespuestaChatbot({required this.texto, required this.lugares});
  final String texto;
  final List<LugarPopular> lugares;
}

/// Operaciones del cliente que no son de viajes en curso (perfil, solicitar, calificar, chatbot).
class ClienteRepository {
  ClienteRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> _map(String path, [Map<String, dynamic>? q]) async {
    final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: q);
    return res.data ?? const {};
  }

  Future<PerfilCliente> perfil() =>
      guard(() async => PerfilCliente.fromJson(await _map('/api/cliente/perfil')));

  Future<PerfilCliente> actualizarPerfil({required String email, required String telefono}) =>
      guard(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/api/cliente/perfil',
          data: {'email': email.trim(), 'telefono': telefono.trim()},
        );
        return PerfilCliente.fromJson(res.data ?? const {});
      });

  Future<PromedioCalificacion> promedio() => guard(
        () async => PromedioCalificacion.fromJson(await _map('/api/cliente/calificaciones/promedio')),
      );

  Future<int> totalViajesFinalizados() => guard(() async {
        final j = await _map('/api/cliente/viajes', {'estado': 'FINALIZADO', 'page': 0, 'size': 1});
        return asInt(j['totalElements']) ?? 0;
      });

  /// GET /api/cliente/viajes/cotizar: precio con la tarifa activa, sin crear el viaje.
  /// Usa la misma fórmula que el backend aplica al solicitar, así el valor coincide.
  Future<double> cotizar({required double km, required int minutos}) => guard(() async {
        final j = await _map('/api/cliente/viajes/cotizar', {'distanciaKm': km, 'duracionMin': minutos});
        return reqDouble(j['precio'], 'precio');
      });

  /// POST /api/cliente/viajes. Distancia y duración vienen de Directions (web)
  /// o de la estimación [Lugares.estimarRuta], igual que en el frontend React.
  Future<Viaje> solicitar({
    required Lugar origen,
    required Lugar destino,
    required int pasajeros,
    required double km,
    required int minutos,
  }) =>
      guard(() async {
        final res = await _dio.post<Map<String, dynamic>>('/api/cliente/viajes', data: {
          'cantidadPasajeros': pasajeros,
          'origenLat': origen.lat,
          'origenLng': origen.lng,
          'destinoLat': destino.lat,
          'destinoLng': destino.lng,
          'origenNombre': _limitar(origen.nombre),
          'destinoNombre': _limitar(destino.nombre),
          'distanciaKm': km,
          'duracionMin': minutos,
        });
        return ViajeDto.fromJson(res.data!).toEntity();
      });

  Future<List<ConductorCercano>> conductoresCercanos(double lat, double lng, {double radioKm = 5}) =>
      guard(() async {
        final res = await _dio.get<List<dynamic>>(
          '/api/cliente/conductores-cercanos',
          queryParameters: {'lat': lat, 'lng': lng, 'radioKm': radioKm},
        );
        return (res.data ?? const [])
            .map((e) => ConductorCercano.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<void> calificar(int viajeId, {required int puntuacion, String? comentario}) => guard(
        () => _dio.post<void>('/api/cliente/viajes/$viajeId/calificar', data: {
          'puntuacion': puntuacion,
          if ((comentario ?? '').trim().isNotEmpty) 'comentario': comentario!.trim(),
        }),
      );

  Future<List<LugarPopular>> lugaresPopulares({int limite = 5}) => guard(() async {
        final res = await _dio.get<List<dynamic>>(
          '/api/cliente/lugares/mas-solicitados',
          queryParameters: {'limite': limite},
        );
        return (res.data ?? const []).map((e) => LugarPopular.fromJson(e as Map<String, dynamic>)).toList();
      });

  /// El chatbot (Gemini) tarda: timeout extendido solo para esta llamada.
  Future<RespuestaChatbot> preguntar(String mensaje) => guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/api/cliente/chatbot/mensaje',
          data: {'mensaje': mensaje},
          options: Options(receiveTimeout: Env.chatbotTimeout),
        );
        final j = res.data ?? const {};
        final lugares = (j['lugaresMasSolicitados'] as List<dynamic>? ?? const [])
            .map((e) => LugarPopular.fromJson(e as Map<String, dynamic>))
            .toList();
        return RespuestaChatbot(texto: asString(j['respuesta']) ?? '', lugares: lugares);
      });

  /// El backend guarda hasta 255 caracteres por nombre.
  static String _limitar(String nombre) => nombre.length <= 255 ? nombre : nombre.substring(0, 255);
}

final clienteRepositoryProvider = Provider((ref) => ClienteRepository(ref.watch(dioProvider)));

final perfilClienteProvider = FutureProvider.autoDispose<PerfilCliente>(
  (ref) => ref.watch(clienteRepositoryProvider).perfil(),
);

class ResumenCliente {
  const ResumenCliente({required this.viajesFinalizados, required this.promedio});
  final int viajesFinalizados;
  final PromedioCalificacion promedio;
}

final resumenClienteProvider = FutureProvider.autoDispose<ResumenCliente>((ref) async {
  final repo = ref.watch(clienteRepositoryProvider);
  final total = repo.totalViajesFinalizados();
  final prom = repo.promedio();
  return ResumenCliente(viajesFinalizados: await total, promedio: await prom);
});

final lugaresPopularesProvider = FutureProvider.autoDispose<List<LugarPopular>>(
  (ref) => ref.watch(clienteRepositoryProvider).lugaresPopulares(),
);

/// Precio estimado para una distancia y duración. La clave es un record, así
/// la misma ruta no vuelve a consultar el backend mientras siga en pantalla.
final cotizacionProvider = FutureProvider.autoDispose.family<double, ({double km, int minutos})>(
  (ref, r) => ref.watch(clienteRepositoryProvider).cotizar(km: r.km, minutos: r.minutos),
);

final conductoresCercanosProvider = FutureProvider.autoDispose.family<List<ConductorCercano>, Lugar>(
  (ref, lugar) => ref.watch(clienteRepositoryProvider).conductoresCercanos(lugar.lat, lugar.lng),
);