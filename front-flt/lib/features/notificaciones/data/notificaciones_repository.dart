import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/guard.dart';
import '../../../core/json/json_read.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/dio_provider.dart';

/// Espejo de `NotificacionResponse`.
class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.leida,
    this.viajeId,
    this.fecha,
  });

  factory Notificacion.fromJson(Map<String, dynamic> j) => Notificacion(
        id: reqInt(j['id'], 'id'),
        tipo: asString(j['tipo']) ?? '',
        mensaje: asString(j['mensaje']) ?? '',
        leida: asBool(j['leida']),
        viajeId: asInt(j['viajeId']),
        fecha: asServerDateTime(j['fechaCreacion']),
      );

  final int id;
  final String tipo;
  final String mensaje;
  final bool leida;
  final int? viajeId;
  final DateTime? fecha;

  Notificacion marcada() =>
      Notificacion(id: id, tipo: tipo, mensaje: mensaje, leida: true, viajeId: viajeId, fecha: fecha);
}

class NotificacionesRepository {
  NotificacionesRepository(this._dio);
  final Dio _dio;

  Future<List<Notificacion>> mias() => guard(() async {
        final res = await _dio.get<List<dynamic>>(ApiPaths.notificacionesMias);
        return (res.data ?? const [])
            .map((e) => Notificacion.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<int> noLeidas() => guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(ApiPaths.notificacionesNoLeidasCount);
        return asInt(res.data?['count']) ?? 0;
      });

  Future<void> marcarLeida(int id) => guard(() => _dio.put<void>(ApiPaths.notificacionLeer(id)));

  Future<void> marcarTodas() => guard(() => _dio.put<void>(ApiPaths.notificacionesLeerTodas));
}

final notificacionesRepositoryProvider =
    Provider((ref) => NotificacionesRepository(ref.watch(dioProvider)));

final notificacionesProvider = FutureProvider.autoDispose<List<Notificacion>>(
  (ref) => ref.watch(notificacionesRepositoryProvider).mias(),
);

/// Contador para el punto de la campana en los top bars.
final notificacionesNoLeidasProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(notificacionesRepositoryProvider).noLeidas(),
);
