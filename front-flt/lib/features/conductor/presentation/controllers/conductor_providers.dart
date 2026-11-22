import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/pagination/pagina.dart';
import '../../../viajes_cliente/domain/entities/estado_viaje.dart';
import '../../../viajes_cliente/domain/entities/viaje.dart';
import '../../data/conductor_repository_impl.dart';
import '../../domain/conductor_models.dart';
import '../../domain/solicitud_pendiente.dart';

/// Solicitud pendiente del FIFO (polling cada Env.pollingInterval).
final solicitudPendienteProvider = StreamProvider.autoDispose<SolicitudPendiente?>(
  (ref) => ref.watch(conductorRepositoryProvider).observarSolicitudPendiente(),
);

final viajeActivoConductorProvider = FutureProvider.autoDispose<Viaje?>(
  (ref) => ref.watch(conductorRepositoryProvider).viajeActivo(),
);

final perfilConductorProvider = FutureProvider.autoDispose<PerfilConductor>(
  (ref) => ref.watch(conductorRepositoryProvider).perfil(),
);

/// Ganancias del día y del mes en curso + últimos pagos (05 Ganancias).
class ResumenGanancias {
  const ResumenGanancias({required this.hoy, required this.mes, required this.ultimosPagos});
  final Ganancias hoy;
  final Ganancias mes;
  final List<Viaje> ultimosPagos;
}

final resumenGananciasProvider = FutureProvider.autoDispose<ResumenGanancias>((ref) async {
  final repo = ref.watch(conductorRepositoryProvider);
  final ahora = DateTime.now();
  // Se lanzan en paralelo; los errores llegan como AppFailure.
  final hoy = repo.gananciasDia(ahora);
  final mes = repo.gananciasMes(ahora.year, ahora.month);
  final pagos = repo.historial(estado: EstadoViaje.finalizado, size: 5);
  return ResumenGanancias(hoy: await hoy, mes: await mes, ultimosPagos: (await pagos).items);
});

/// Filtros del historial del conductor (04 Historial).
enum PeriodoHistorial { todos, semana, mes }

class ConsultaHistorial {
  const ConsultaHistorial(this.periodo, this.page);
  final PeriodoHistorial periodo;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is ConsultaHistorial && other.periodo == periodo && other.page == page;

  @override
  int get hashCode => Object.hash(periodo, page);
}

const tamanoPaginaHistorial = 4;

final historialConductorProvider =
    FutureProvider.autoDispose.family<Pagina<Viaje>, ConsultaHistorial>((ref, q) {
  final ahora = DateTime.now();
  final desde = switch (q.periodo) {
    PeriodoHistorial.todos => null,
    PeriodoHistorial.semana => DateTime(ahora.year, ahora.month, ahora.day)
        .subtract(Duration(days: ahora.weekday - 1)),
    PeriodoHistorial.mes => DateTime(ahora.year, ahora.month),
  };
  return ref
      .watch(conductorRepositoryProvider)
      .historial(desde: desde, page: q.page, size: tamanoPaginaHistorial);
});

/// Promedio + reseñas (06 Mis calificaciones).
class ResumenResenas {
  const ResumenResenas({required this.promedio, required this.resenas});
  final PromedioCalificacion promedio;
  final List<Calificacion> resenas;
}

final resenasProvider = FutureProvider.autoDispose<ResumenResenas>((ref) async {
  final repo = ref.watch(conductorRepositoryProvider);
  final prom = repo.promedio();
  final pag = repo.calificaciones();
  return ResumenResenas(promedio: await prom, resenas: (await pag).items);
});
