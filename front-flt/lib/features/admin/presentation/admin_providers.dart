import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pagination/pagina.dart';
import '../../viajes_cliente/domain/entities/estado_viaje.dart';
import '../../viajes_cliente/domain/entities/viaje.dart';
import '../data/admin_repository.dart';

final perfilAdminProvider = FutureProvider.autoDispose<PerfilUsuario>(
  (ref) => ref.watch(adminRepositoryProvider).perfil(),
);

final conductoresAdminProvider = FutureProvider.autoDispose<List<ConductorAdmin>>(
  (ref) => ref.watch(adminRepositoryProvider).conductores(),
);

final vehiculosAdminProvider = FutureProvider.autoDispose<List<VehiculoAdmin>>(
  (ref) => ref.watch(adminRepositoryProvider).vehiculos(),
);

final clientesAdminProvider = FutureProvider.autoDispose<List<ClienteAdmin>>(
  (ref) => ref.watch(adminRepositoryProvider).clientes(),
);

final dashboardUrlProvider = FutureProvider.autoDispose<String>(
  (ref) => ref.watch(adminRepositoryProvider).dashboardUrl(),
);

// ───────────── 03 Inicio ─────────────

class ResumenInicio {
  const ResumenInicio({
    required this.viajesMes,
    required this.viajesMesAnterior,
    required this.conductoresDisponibles,
    required this.viajesHoy,
  });

  final int viajesMes;
  final int viajesMesAnterior;
  final int conductoresDisponibles;
  final int viajesHoy;
}

final resumenInicioProvider = FutureProvider.autoDispose<ResumenInicio>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final hoy = DateTime.now();
  final inicioMes = DateTime(hoy.year, hoy.month);
  final inicioAnterior = DateTime(hoy.year, hoy.month - 1);
  // Mismo número de días transcurridos en el mes anterior, para comparar justo.
  final corteAnterior = DateTime(hoy.year, hoy.month - 1, hoy.day);

  final dias = repo.viajesPorDia(inicioAnterior, hoy);
  final conductores = repo.conductores();
  final viajesHoy = repo.viajesDelDia(hoy);

  final lista = await dias;
  int sumar(DateTime desde, DateTime hasta) => lista
      .where((d) => !d.fecha.isBefore(desde) && !d.fecha.isAfter(hasta))
      .fold(0, (a, d) => a + d.cantidad);

  return ResumenInicio(
    viajesMes: sumar(inicioMes, hoy),
    viajesMesAnterior: sumar(inicioAnterior, corteAnterior),
    conductoresDisponibles: (await conductores).where((c) => c.activo && c.disponible).length,
    viajesHoy: await viajesHoy,
  );
});

// ───────────── 09 Viajes ─────────────

class ConsultaViajes {
  const ConsultaViajes(this.estado, this.page);
  final EstadoViaje? estado;
  final int page;

  @override
  bool operator ==(Object other) => other is ConsultaViajes && other.estado == estado && other.page == page;

  @override
  int get hashCode => Object.hash(estado, page);
}

const tamanoPaginaViajesAdmin = 5;

final viajesAdminProvider = FutureProvider.autoDispose.family<Pagina<Viaje>, ConsultaViajes>(
  (ref, q) => ref
      .watch(adminRepositoryProvider)
      .viajes(estado: q.estado, page: q.page, size: tamanoPaginaViajesAdmin),
);
