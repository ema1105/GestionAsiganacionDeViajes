import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/periodo.dart';
import '../../domain/prediccion.dart';
import '../prediccion_providers.dart';
import '../widgets/graficas_prediccion.dart';
import '../widgets/prediccion_widgets.dart';

/// Mockup admin 04 · Predicción mensual (demanda estimada de un mes vs el año anterior).
class PrediccionPage extends ConsumerWidget {
  const PrediccionPage({super.key});

  static void refrescar(WidgetRef ref) => ref
    ..invalidate(saludPrediccionProvider)
    ..invalidate(fichaModeloProvider)
    ..invalidate(prediccionProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ficha = ref.watch(fichaModeloProvider);

    return GavPage(
      onRefresh: () async {
        refrescar(ref);
        await ref.read(fichaModeloProvider.future);
      },
      children: [
        GavTopBar(
          title: 'Demanda mensual',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GavIconButton(
                icon: Icons.model_training,
                tooltip: 'Entrenar modelo',
                onTap: () => context.push('/admin/prediccion/modelo'),
              ),
              const SizedBox(width: 8),
              GavIconButton(
                icon: Icons.refresh,
                tooltip: 'Actualizar',
                onTap: () => refrescar(ref),
              ),
            ],
          ),
        ),
        const EstadoConexionPrediccion(),
        GavCard(
          padding: const EdgeInsets.all(14),
          child: InkWell(
            onTap: () => context.push('/admin/prediccion/modelo'),
            child: Row(
              children: [
                const GavIconBox(icon: Icons.model_training, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Modelo predictivo', style: GavText.strong(context, size: 14)),
                      Text('Reentrenar con los viajes actuales y ver sus métricas',
                          style: GavText.muted(context, size: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        AsyncValueView<FichaModelo>(
          value: ficha,
          onRetry: () => refrescar(ref),
          data: (f) => _Contenido(ficha: f),
        ),
      ],
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.ficha});
  final FichaModelo ficha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodo = periodoActivo(ficha, ref.watch(periodoSeleccionadoProvider));
    final async = ref.watch(prediccionProvider(periodo));
    final seleccion = ref.read(periodoSeleccionadoProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectorMes(
          periodo: periodo,
          onAnterior: ficha.admite(periodo.anterior) ? () => seleccion.elegir(periodo.anterior) : null,
          onSiguiente: ficha.admite(periodo.siguiente) ? () => seleccion.elegir(periodo.siguiente) : null,
        ),
        const SizedBox(height: 12),
        AsyncValueView<Prediccion>(
          value: async,
          onRetry: () => ref.invalidate(prediccionProvider(periodo)),
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroPrediccion(
                prediccion: p,
                onTap: () => context.push('/admin/prediccion/detalle?periodo=${periodo.api}'),
              ),
              _CardGrafico(prediccion: p),
              _OtrosMeses(prediccion: p, onElegir: seleccion.elegir),
              const SizedBox(height: 12),
              Text(notaModelo(p.modelo), style: GavText.muted(context, size: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

/// "‹  Octubre 2027  ›". Las flechas se deshabilitan fuera del horizonte del modelo.
class _SelectorMes extends StatelessWidget {
  const _SelectorMes({required this.periodo, this.onAnterior, this.onSiguiente});
  final Periodo periodo;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  Widget _flecha(IconData icon, String tooltip, VoidCallback? onTap) => Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: GavIconButton(icon: icon, tooltip: tooltip, onTap: onTap),
      );

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _flecha(Icons.chevron_left, 'Mes anterior', onAnterior),
          Expanded(
            child: Text(
              '${Fmt.mes(periodo.mes)} ${periodo.anio}',
              textAlign: TextAlign.center,
              style: GavText.strong(context, size: 16),
            ),
          ),
          _flecha(Icons.chevron_right, 'Mes siguiente', onSiguiente),
        ],
      );
}

class _HeroPrediccion extends StatelessWidget {
  const _HeroPrediccion({required this.prediccion, required this.onTap});
  final Prediccion prediccion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = prediccion.objetivo;
    final b = prediccion.base;
    return GavCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tituloPeriodo(o)} · predicción', style: GavText.muted(context, size: 13)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(Fmt.miles(o.predichas), style: GavText.kpi(context, size: 48)),
                    const SizedBox(width: 8),
                    Text('solicitudes', style: GavText.muted(context, size: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'frente a ${Fmt.miles(b.reales)} en ${tituloBase(b)}',
                  style: GavText.muted(context, size: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          BadgeTendencia(prediccion.comparacion),
        ],
      ),
    );
  }
}

class _CardGrafico extends StatelessWidget {
  const _CardGrafico({required this.prediccion});
  final Prediccion prediccion;

  @override
  Widget build(BuildContext context) {
    final o = prediccion.objetivo;
    final b = prediccion.base;
    final titulo = o.esUnMes
        ? '${Fmt.mes(o.desde.mes)}: ${b.desde.anio} frente a ${o.desde.anio}'
        : '${b.etiqueta} frente a ${o.etiqueta}';
    String corta(Periodo p) => '${Fmt.mesCorto(p.mes)} ${p.anio}';

    return GavCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo, style: GavText.strong(context, size: 14))),
              Text('Línea: rango probable', style: GavText.muted(context, size: 11)),
            ],
          ),
          const SizedBox(height: 8),
          LienzoGrafica(
            height: 167,
            painter: BarrasComparacionPainter(
              real: b.reales,
              prediccion: o.predichas,
              minimo: o.intervalo.min,
              maximo: o.intervalo.max,
              etiquetaReal: o.esUnMes ? '${corta(b.desde)} · real' : 'Base · real',
              etiquetaPrediccion: o.esUnMes ? '${corta(o.desde)} · predicción' : 'Predicción',
            ),
          ),
        ],
      ),
    );
  }
}

/// "Otros meses de 2027": del mes más reciente al más antiguo, sin el mes elegido.
class _OtrosMeses extends StatelessWidget {
  const _OtrosMeses({required this.prediccion, required this.onElegir});
  final Prediccion prediccion;
  final ValueChanged<Periodo> onElegir;

  @override
  Widget build(BuildContext context) {
    final meses = prediccion.meses.where((m) => !m.enPeriodo && m.tienePrediccion).toList()
      ..sort((a, b) => b.periodo.compareTo(a.periodo));
    if (meses.isEmpty) return const SizedBox.shrink();

    final anios = meses.map((m) => m.periodo.anio).toSet();
    final titulo = anios.length == 1 ? 'Otros meses de ${anios.first}' : 'Otros meses';
    final anioBase = prediccion.base.desde.anio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Text(titulo, style: GavText.strong(context, size: 14)),
        ),
        for (var i = 0; i < meses.length; i++)
          FilaMesPrediccion(
            mes: meses[i],
            anioBase: anioBase + (meses[i].periodo.anio - prediccion.objetivo.desde.anio),
            ultima: i == meses.length - 1,
            onTap: () => onElegir(meses[i].periodo),
          ),
      ],
    );
  }
}
