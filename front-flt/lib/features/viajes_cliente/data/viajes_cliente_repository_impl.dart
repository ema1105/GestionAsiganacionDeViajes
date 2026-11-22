import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/guard.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/pagination/pagina.dart';
import '../domain/entities/viaje.dart';
import '../domain/viajes_repository.dart';
import 'datasources/viajes_cliente_remote_data_source.dart';

class ViajesClienteRepositoryImpl implements ViajesClienteRepository {
  ViajesClienteRepositoryImpl(this._remote);
  final ViajesClienteRemoteDataSource _remote;

  @override
  Future<Viaje?> viajeActivo() => guard(() async => (await _remote.viajeActivo())?.toEntity());

  @override
  Future<Pagina<Viaje>> historial(FiltroViajes filtro, {int page = 0, int size = 20}) =>
      guard(() async {
        final dto = await _remote.historial(
          estado: filtro.estado,
          desde: filtro.desde,
          hasta: filtro.hasta,
          page: page,
          size: size,
        );
        return dto.toPagina((v) => v.toEntity());
      });

  @override
  Future<void> cancelar(int viajeId) => guard(() => _remote.cancelar(viajeId));

  @override
  Stream<PuntoSeguimiento?> seguirViaje(int viajeId) async* {
    while (true) {
      try {
        yield (await guard(() => _remote.ultimoPunto(viajeId)))?.toEntity();
      } on AppFailure catch (f) {
        // Errores transitorios: se ignora este ciclo y se reintenta en el siguiente.
        // 401/403/404: se corta el stream y la UI muestra el error.
        if (!f.isRetryable) rethrow;
      }
      await Future<void>.delayed(Env.pollingInterval);
    }
  }
}

final viajesClienteRepositoryProvider = Provider<ViajesClienteRepository>(
  (ref) => ViajesClienteRepositoryImpl(ViajesClienteRemoteDataSource(ref.watch(dioProvider))),
);
