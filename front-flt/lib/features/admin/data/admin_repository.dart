import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/guard.dart';
import '../../../core/json/json_read.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/pagination/pagina.dart';
import '../../viajes_cliente/data/dtos/viaje_dto.dart';
import '../../viajes_cliente/domain/entities/estado_viaje.dart';
import '../../viajes_cliente/domain/entities/viaje.dart';

// ───────────────────────── Modelos ─────────────────────────

/// Espejo de `ConductorResponse`.
class ConductorAdmin {
  const ConductorAdmin({
    required this.id,
    required this.nombre,
    required this.disponible,
    required this.activo,
    this.vehiculo,
    this.placa,
    this.licencia,
  });

  factory ConductorAdmin.fromJson(Map<String, dynamic> j) => ConductorAdmin(
        id: asInt(j['usuarioId']) ?? 0,
        nombre: '${asString(j['nombreCompleto']) ?? ''} ${asString(j['apellidosCompletos']) ?? ''}'.trim(),
        disponible: asBool(j['disponibilidad']),
        activo: asBool(j['activo'], orElse: true),
        vehiculo: [asString(j['marcaVehiculo']), asString(j['modeloVehiculo'])]
            .whereType<String>()
            .join(' '),
        placa: asString(j['placaVehiculo']),
        licencia: asString(j['tipoLicencia']),
      );

  final int id;
  final String nombre;
  final bool disponible;
  final bool activo;
  final String? vehiculo;
  final String? placa;
  final String? licencia;
}

/// Espejo de `VehiculoResponse`.
class VehiculoAdmin {
  const VehiculoAdmin({
    required this.id,
    required this.descripcion,
    required this.placa,
    required this.capacidad,
    this.categoria,
    this.conductor,
  });

  factory VehiculoAdmin.fromJson(Map<String, dynamic> j) => VehiculoAdmin(
        id: asInt(j['id']) ?? 0,
        descripcion: '${asString(j['marca']) ?? ''} ${asString(j['modelo']) ?? ''}'.trim(),
        placa: asString(j['placa']) ?? '',
        capacidad: asInt(j['capacidadMaxima']) ?? 0,
        categoria: asString(j['categoriaNombre']),
        conductor: asString(j['conductorAsignadoNombre']),
      );

  final int id;
  final String descripcion;
  final String placa;
  final int capacidad;
  final String? categoria;
  final String? conductor;
}

/// Cliente según `GET /api/admin/clientes` (mapa con totalViajes).
class ClienteAdmin {
  const ClienteAdmin({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.totalViajes,
  });

  factory ClienteAdmin.fromJson(Map<String, dynamic> j) => ClienteAdmin(
        id: asInt(j['id']) ?? 0,
        nombre: '${asString(j['nombreCompleto']) ?? ''} ${asString(j['apellidosCompletos']) ?? ''}'.trim(),
        email: asString(j['email']) ?? '',
        telefono: asString(j['telefono']) ?? '',
        totalViajes: asInt(j['totalViajes']) ?? 0,
      );

  final int id;
  final String nombre;
  final String email;
  final String telefono;
  final int totalViajes;
}

/// Espejo de `UsuarioResponse` (perfil del admin).
class PerfilUsuario {
  const PerfilUsuario({
    required this.nombre,
    required this.apellidos,
    required this.usuario,
    required this.email,
    required this.telefono,
  });

  factory PerfilUsuario.fromJson(Map<String, dynamic> j) => PerfilUsuario(
        nombre: asString(j['nombreCompleto']) ?? '',
        apellidos: asString(j['apellidosCompletos']) ?? '',
        usuario: asString(j['nombreUsuario']) ?? '',
        email: asString(j['email']) ?? '',
        telefono: asString(j['telefono']) ?? '',
      );

  final String nombre;
  final String apellidos;
  final String usuario;
  final String email;
  final String telefono;

  String get nombreCompleto => '$nombre $apellidos'.trim();
}

/// Viajes de un día (`ViajesPorDiaResponse`).
class ViajesDia {
  const ViajesDia(this.fecha, this.cantidad);
  final DateTime fecha;
  final int cantidad;
}

// ───────────────────────── Repositorio ─────────────────────────

class AdminRepository {
  AdminRepository(this._dio);
  final Dio _dio;

  String _fecha(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<Map<String, dynamic>> _map(String path, [Map<String, dynamic>? q]) async {
    final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: q);
    return res.data ?? const {};
  }

  Future<List<Map<String, dynamic>>> _list(String path, [Map<String, dynamic>? q]) async {
    final res = await _dio.get<List<dynamic>>(path, queryParameters: q);
    return (res.data ?? const []).cast<Map<String, dynamic>>();
  }

  Future<PerfilUsuario> perfil() =>
      guard(() async => PerfilUsuario.fromJson(await _map(ApiPaths.adminPerfil)));

  Future<PerfilUsuario> actualizarPerfil({required String email, required String telefono}) =>
      guard(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          ApiPaths.adminPerfil,
          data: {'email': email.trim(), 'telefono': telefono.trim()},
        );
        return PerfilUsuario.fromJson(res.data ?? const {});
      });

  Future<List<ConductorAdmin>> conductores() => guard(() async =>
      (await _list(ApiPaths.adminConductores, {'incluirInactivos': true})).map(ConductorAdmin.fromJson).toList());

  Future<List<VehiculoAdmin>> vehiculos() =>
      guard(() async => (await _list(ApiPaths.adminVehiculos)).map(VehiculoAdmin.fromJson).toList());

  Future<List<ClienteAdmin>> clientes() =>
      guard(() async => (await _list(ApiPaths.adminClientes)).map(ClienteAdmin.fromJson).toList());

  Future<Pagina<Viaje>> viajes({EstadoViaje? estado, int page = 0, int size = 5}) => guard(() async {
        final json = await _map(ApiPaths.adminViajes, {
          if (estado != null) 'estado': estado.api,
          'page': page,
          'size': size,
        });
        return PageDto.fromJson(json, ViajeDto.fromJson).toPagina((v) => v.toEntity());
      });

  Future<int> viajesDelDia(DateTime fecha) => guard(() async =>
      asInt((await _map(ApiPaths.adminViajesDia, {'fecha': _fecha(fecha)}))['cantidad']) ?? 0);

  Future<double> gananciasMes(int anio, int mes) => guard(() async =>
      asDouble((await _map(ApiPaths.adminGananciasMes, {'anio': anio, 'mes': mes}))['total']) ?? 0);

  Future<List<ViajesDia>> viajesPorDia(DateTime desde, DateTime hasta) => guard(() async {
        final lista = await _list(ApiPaths.adminViajesPorDia, {'desde': _fecha(desde), 'hasta': _fecha(hasta)});
        return lista
            .map((j) => ViajesDia(
                  DateTime.tryParse(asString(j['fecha']) ?? '') ?? desde,
                  asInt(j['cantidad']) ?? 0,
                ))
            .toList();
      });

  Future<String> dashboardUrl() =>
      guard(() async => asString((await _map(ApiPaths.adminDashboardUrl))['url']) ?? '');
}

final adminRepositoryProvider = Provider((ref) => AdminRepository(ref.watch(dioProvider)));
