import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/pagination/paginated_state.dart';
import '../../data/viajes_cliente_repository_impl.dart';
import '../../domain/entities/viaje.dart';

/// Viaje activo del cliente (null = no tiene). autoDispose: se descarta al salir.
/// Viaje activo del cliente (null = no tiene). Se consulta cada Env.pollingInterval
/// para reflejar los cambios de estado (buscando → aceptado → en camino → en curso).
final viajeActivoClienteProvider = StreamProvider.autoDispose<Viaje?>((ref) async* {
  final repo = ref.watch(viajesClienteRepositoryProvider);
  while (true) {
    yield await repo.viajeActivo();
    await Future<void>.delayed(Env.pollingInterval);
  }
});

/// Seguimiento en vivo. Al salir de la pantalla, autoDispose cancela el polling.
final seguimientoViajeProvider = StreamProvider.autoDispose.family<PuntoSeguimiento?, int>(
  (ref, viajeId) => ref.watch(viajesClienteRepositoryProvider).seguirViaje(viajeId),
);

/// Historial paginado. Cada filtro distinto es una instancia nueva (reinicio limpio).
class HistorialViajesController extends AsyncNotifier<PaginatedState<Viaje>> {
  HistorialViajesController(this.filtro);

  final FiltroViajes filtro;
  static const _size = 20;

  @override
  Future<PaginatedState<Viaje>> build() async {
    final p = await ref.watch(viajesClienteRepositoryProvider).historial(filtro, size: _size);
    return PaginatedState(items: p.items, page: p.page, hasMore: !p.isLast);
  }

  Future<void> cargarMas() async {
    final actual = state.value;
    if (actual == null || !actual.hasMore || actual.cargandoMas) return;

    state = AsyncData(actual.copyWith(cargandoMas: true, limpiarError: true));
    try {
      final p = await ref
          .read(viajesClienteRepositoryProvider)
          .historial(filtro, page: actual.page + 1, size: _size);
      // Paginación por offset: si entran viajes nuevos, pueden repetirse ids.
      final ids = actual.items.map((v) => v.id).toSet();
      state = AsyncData(
        actual.copyWith(
          items: [...actual.items, ...p.items.where((v) => !ids.contains(v.id))],
          page: p.page,
          hasMore: !p.isLast,
          cargandoMas: false,
        ),
      );
    } catch (e) {
      state = AsyncData(actual.copyWith(cargandoMas: false, errorCargaMas: e));
    }
  }
}

final historialViajesProvider = AsyncNotifierProvider.autoDispose
    .family<HistorialViajesController, PaginatedState<Viaje>, FiltroViajes>(
  HistorialViajesController.new,
);
