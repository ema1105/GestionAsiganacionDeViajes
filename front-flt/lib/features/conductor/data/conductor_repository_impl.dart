import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/guard.dart';
import '../../../core/json/json_read.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/pagination/pagina.dart';
import '../../viajes_cliente/data/dtos/viaje_dto.dart';
import '../../viajes_cliente/domain/entities/estado_viaje.dart';
import '../../viajes_cliente/domain/entities/viaje.dart';
import '../domain/conductor_models.dart';
import '../domain/solicitud_pendiente.dart';
import 'dtos/solicitud_pendiente_dto.dart';

class ConductorRemoteDataSource {
  ConductorRemoteDataSource(this._dio);
  final Dio _dio;

  Future<SolicitudPendienteDto?> solicitudPendiente() async {
    final res = await _dio.get<dynamic>(ApiPaths.conductorSolicitudPendiente);
    final data = res.data;
    if (res.statusCode == 204 || data is! Map<String, dynamic>) return null;
    return SolicitudPendienteDto.fromJson(data);
  }

  Future<ViajeDto?> viajeActivo() async {
    final res = await _dio.get<dynamic>(ApiPaths.conductorViajeActivo);
    final data = res.data;
    if (res.statusCode == 204 || data is! Map<String, dynamic>) return null;
    return ViajeDto.fromJson(data);
  }

  Future<ViajeDto> responder(int viajeId, bool aceptar) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiPaths.conductorResponder(viajeId),
      queryParameters: {'aceptar': aceptar},
    );
    return ViajeDto.fromJson(res.data!);
  }

  Future<ViajeDto> post(String path) async {
    final res = await _dio.post<Map<String, dynamic>>(path);
    return ViajeDto.fromJson(res.data!);
  }

  Future<void> ubicacion(double lat, double lng) =>
      _dio.post<void>(ApiPaths.conductorUbicacion, data: {'lat': lat, 'lng': lng});

  Future<void> postVoid(String path, Map<String, dynamic> body) => _dio.post<void>(path, data: body);

  Future<Map<String, dynamic>> getMap(String path, [Map<String, dynamic>? q]) async {
    final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: q);
    return res.data ?? const {};
  }

  Future<Map<String, dynamic>> putMap(String path, Map<String, dynamic> body) async {
    final res = await _dio.put<Map<String, dynamic>>(path, data: body);
    return res.data ?? const {};
  }
}

class ConductorRepositoryImpl implements ConductorRepository {
  ConductorRepositoryImpl(this._remote);
  final ConductorRemoteDataSource _remote;

  @override
  Stream<SolicitudPendiente?> observarSolicitudPendiente() async* {
    while (true) {
      try {
        yield (await guard(_remote.solicitudPendiente))?.toEntity();
      } on AppFailure catch (f) {
        if (!f.isRetryable) rethrow;
      }
      await Future<void>.delayed(Env.pollingInterval);
    }
  }

  @override
  Future<Viaje?> viajeActivo() => guard(() async => (await _remote.viajeActivo())?.toEntity());

  @override
  Future<Viaje> responder(int viajeId, {required bool aceptar}) =>
      guard(() async => (await _remote.responder(viajeId, aceptar)).toEntity());

  @override
  Future<Viaje> ejecutar(AccionConductor accion, int viajeId) => guard(() async {
        final path = switch (accion) {
          AccionConductor.enCamino => ApiPaths.conductorEnCamino(viajeId),
          AccionConductor.iniciar => ApiPaths.conductorIniciar(viajeId),
          AccionConductor.finalizar => ApiPaths.conductorFinalizar(viajeId),
        };
        return (await _remote.post(path)).toEntity();
      });

  @override
  Future<void> reportarUbicacion(double lat, double lng) =>
      guard(() => _remote.ubicacion(lat, lng));

  @override
  Future<void> registrarSeguimiento(int viajeId, double lat, double lng) => guard(
        () => _remote.postVoid(ApiPaths.conductorSeguimiento(viajeId), {'lat': lat, 'lng': lng}),
      );

  @override
  Future<PerfilConductor> perfil() =>
      guard(() async => PerfilConductor.fromJson(await _remote.getMap(ApiPaths.conductorPerfil)));

  @override
  Future<PerfilConductor> actualizarPerfil({String? email, String? telefono}) => guard(() async {
        final body = <String, dynamic>{
          if (email != null) 'email': email.trim(),
          if (telefono != null) 'telefono': telefono.trim(),
        };
        return PerfilConductor.fromJson(await _remote.putMap(ApiPaths.conductorPerfil, body));
      });

  @override
  Future<Ganancias> gananciasDia(DateTime fecha) => guard(() async {
        final f = fecha.toIso8601String().substring(0, 10);
        return Ganancias.fromJson(await _remote.getMap(ApiPaths.conductorGananciasDia, {'fecha': f}));
      });

  @override
  Future<Ganancias> gananciasMes(int anio, int mes) => guard(() async => Ganancias.fromJson(
        await _remote.getMap(ApiPaths.conductorGananciasMes, {'anio': anio, 'mes': mes}),
      ));

  @override
  Future<Pagina<Viaje>> historial({
    EstadoViaje? estado,
    DateTime? desde,
    DateTime? hasta,
    int page = 0,
    int size = 4,
  }) =>
      guard(() async {
        final json = await _remote.getMap(ApiPaths.conductorViajes, {
          if (estado != null) 'estado': estado.api,
          if (desde != null) 'desde': toServerIso(desde),
          if (hasta != null) 'hasta': toServerIso(hasta),
          'page': page,
          'size': size,
        });
        return PageDto.fromJson(json, ViajeDto.fromJson).toPagina((v) => v.toEntity());
      });

  @override
  Future<Pagina<Calificacion>> calificaciones({int page = 0, int size = 20}) => guard(() async {
        final json = await _remote.getMap(ApiPaths.conductorCalificaciones, {'page': page, 'size': size});
        return PageDto.fromJson(json, Calificacion.fromJson).toPagina((c) => c);
      });

  @override
  Future<PromedioCalificacion> promedio() => guard(() async =>
      PromedioCalificacion.fromJson(await _remote.getMap(ApiPaths.conductorCalificacionesPromedio)));
}

final conductorRepositoryProvider = Provider<ConductorRepository>(
  (ref) => ConductorRepositoryImpl(ConductorRemoteDataSource(ref.watch(dioProvider))),
);
