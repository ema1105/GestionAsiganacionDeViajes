import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/periodo.dart';
import '../../domain/prediccion.dart';
import '../prediccion_providers.dart';
import '../widgets/prediccion_widgets.dart';

/// Mockup admin 05 · Detalle del periodo. Reutiliza la predicción ya cargada en la 04
/// (misma clave del provider), así que abre sin una nueva petición.
class DetallePeriodoPage extends ConsumerWidget {
  const DetallePeriodoPage({super.key, required this.periodo});

  /// null si la ruta llegó con un `?periodo=` inválido.
  final Periodo? periodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = periodo;
    void volver() => context.canPop() ? context.pop() : context.go('/admin/prediccion');

    if (p == null) {
      return GavPage(
        children: [
          GavTopBar(eyebrow: 'GAV · Predicción', title: 'Detalle', onBack: volver),
          const EmptyView(mensaje: 'Periodo no válido', icono: Icons.bar_chart_rounded),
        ],
      );
    }

    final async = ref.watch(prediccionProvider(p));
    final ficha = ref.watch(fichaModeloProvider).value;

    return GavPage(
      onRefresh: () => ref.refresh(prediccionProvider(p).future),
      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: GavPrimaryButton(label: 'Ver otros meses', onPressed: volver),
        ),
      ),
      children: [
        // El título sale del periodo de la ruta: se ve (con el botón volver) aunque
        // la predicción esté cargando o haya fallado.
        GavTopBar(
          eyebrow: 'GAV · Predicción',
          title: '${Fmt.mes(p.mes)} ${p.anio}',
          subtitle: 'Frente a ${Fmt.mes(p.mes).toLowerCase()} ${p.anio - 1}',
          onBack: volver,
        ),
        AsyncValueView<Prediccion>(
          value: async,
          onRetry: () => ref.invalidate(prediccionProvider(p)),
          data: (pr) => _Detalle(prediccion: pr, ficha: ficha),
        ),
      ],
    );
  }
}

class _Detalle extends StatelessWidget {
  const _Detalle({required this.prediccion, required this.ficha});
  final Prediccion prediccion;
  final FichaModelo? ficha;

  @override
  Widget build(BuildContext context) {
    final o = prediccion.objetivo;
    final b = prediccion.base;
    final c = prediccion.comparacion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(objetivo: o, base: b, comparacion: c),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CifraCard(
                  titulo: 'Periodo base · ${b.etiqueta}',
                  valor: Fmt.miles(b.reales),
                  pie: 'solicitudes reales',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CifraCard(
                  titulo: 'Rango probable',
                  valor: '${Fmt.miles(o.intervalo.min)} a ${Fmt.miles(o.intervalo.max)}',
                  pie: 'solicitudes',
                  dorado: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Promedio por día', style: GavText.strong(context, size: 14)),
        const SizedBox(height: 4),
        _FilaPromedio(
          etiqueta: '${tituloPeriodo(o)} (${o.dias} días)',
          valor: o.predichas / o.dias,
        ),
        _FilaPromedio(
          etiqueta: '${_capitalizar(tituloBase(b))} (${b.dias} días)',
          valor: b.reales / b.dias,
        ),
        const SizedBox(height: 20),
        _SobreElModelo(prediccion: prediccion, ficha: ficha),
      ],
    );
  }

  static String _capitalizar(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Hero extends StatelessWidget {
  const _Hero({required this.objetivo, required this.base, required this.comparacion});
  final PeriodoObjetivo objetivo;
  final PeriodoBase base;
  final Comparacion comparacion;

  String _diferencia() {
    final d = comparacion.variacionAbsoluta;
    final ref = tituloBase(base);
    if (d == 0) return 'Las mismas solicitudes que en $ref';
    final n = d.abs();
    final palabra = n == 1 ? 'solicitud' : 'solicitudes';
    return '${Fmt.miles(n)} $palabra ${d > 0 ? 'más' : 'menos'} que en $ref';
  }

  @override
  Widget build(BuildContext context) => GavCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solicitudes predichas · ${objetivo.etiqueta}',
                        style: GavText.muted(context, size: 13),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(Fmt.miles(objetivo.predichas), style: GavText.kpi(context, size: 58)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                BadgeTendencia(comparacion),
              ],
            ),
            const SizedBox(height: 14),
            Text(_diferencia(), style: GavText.muted(context, size: 14)),
          ],
        ),
      );
}

class _CifraCard extends StatelessWidget {
  const _CifraCard({required this.titulo, required this.valor, required this.pie, this.dorado = false});
  final String titulo;
  final String valor;
  final String pie;
  final bool dorado;

  @override
  Widget build(BuildContext context) => GavCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: GavText.muted(context, size: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                style: GavText.kpi(context, size: 28, color: dorado ? context.gav.gold : null),
              ),
            ),
            const SizedBox(height: 4),
            Text(pie, style: GavText.muted(context, size: 12)),
          ],
        ),
      );
}

class _FilaPromedio extends StatelessWidget {
  const _FilaPromedio({required this.etiqueta, required this.valor});
  final String etiqueta;
  final double valor;

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.gav.border))),
        child: Row(
          children: [
            Expanded(child: Text(etiqueta, style: GavText.body(context, size: 14))),
            Text('${Fmt.unDecimal(valor)} solicitudes', style: GavText.strong(context, size: 14)),
          ],
        ),
      );
}

class _SobreElModelo extends StatelessWidget {
  const _SobreElModelo({required this.prediccion, required this.ficha});
  final Prediccion prediccion;
  final FichaModelo? ficha;

  @override
  Widget build(BuildContext context) {
    final m = prediccion.modelo;
    final entrenado = ficha?.entrenadoEn;
    final pie = entrenado != null
        ? 'Modelo entrenado el ${Fmt.fechaHora(entrenado)}'
        : 'Consultado el ${Fmt.fechaHora(prediccion.generadoEn)}';
    return GavCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sobre el modelo', style: GavText.strong(context, size: 14)),
          const SizedBox(height: 8),
          Text(
            'Red neuronal artificial (RNA) v${m.version}. Error medio absoluto (MAE) de '
            '${m.mae.round()} solicitudes por mes y RMSE de ${m.rmse.round()} sobre los datos '
            'de validación.',
            style: GavText.muted(context, size: 13).copyWith(height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(pie, style: GavText.body(context, size: 11, color: context.gav.textMuted)),
        ],
      ),
    );
  }
}
