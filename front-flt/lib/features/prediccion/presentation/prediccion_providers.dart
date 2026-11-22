import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prediccion_repository_impl.dart';
import '../domain/periodo.dart';
import '../domain/prediccion.dart';

/// Ficha del modelo: límites del selector de mes y la tarjeta "Sobre el modelo".
final fichaModeloProvider = FutureProvider.autoDispose<FichaModelo>(
  (ref) => ref.watch(prediccionRepositoryProvider).ficha(),
);

/// Indicador de conexión (punto verde/ámbar/rojo).
final saludPrediccionProvider = FutureProvider.autoDispose<EstadoServicio>(
  (ref) => ref.watch(prediccionRepositoryProvider).salud(),
);

/// Predicción de un mes contra el mismo mes del año anterior.
/// La comparten Predicción (04), Detalle (05) e Histórico (06, con enero de cada año).
final prediccionProvider = FutureProvider.autoDispose.family<Prediccion, Periodo>(
  (ref, periodo) => ref.watch(prediccionRepositoryProvider).prediccion(periodo),
);

/// Mes elegido por el usuario. null = todavía no elige (se usa el primer mes pronosticado).
/// No es autoDispose: se conserva al cambiar de pestaña.
class PeriodoSeleccionado extends Notifier<Periodo?> {
  @override
  Periodo? build() => null;

  void elegir(Periodo p) => state = p;
}

final periodoSeleccionadoProvider =
    NotifierProvider<PeriodoSeleccionado, Periodo?>(PeriodoSeleccionado.new);

/// Mes efectivo que muestra la pestaña Predicción, dentro de los límites del modelo.
Periodo periodoActivo(FichaModelo ficha, Periodo? elegido) {
  final p = elegido ?? ficha.primerPronostico;
  if (p < ficha.primerConsultable) return ficha.primerConsultable;
  if (p > ficha.horizonteHasta) return ficha.horizonteHasta;
  return p;
}
