import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../domain/prediccion.dart';
import '../prediccion_providers.dart';

/// "● Servicio de predicción conectado · 10.0.2.2:8000" (mockup 04).
class EstadoConexionPrediccion extends ConsumerWidget {
  const EstadoConexionPrediccion({super.key});

  static String get _host {
    final uri = Uri.tryParse(Env.prediccionBaseUrl);
    return (uri == null || uri.authority.isEmpty) ? Env.prediccionBaseUrl : uri.authority;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = context.gav;
    final salud = ref.watch(saludPrediccionProvider);
    final (color, texto) = salud.when(
      data: (e) => switch (e) {
        EstadoServicio.ok => (g.success, 'Servicio de predicción conectado'),
        EstadoServicio.sinModelo => (g.gold, 'Servicio sin modelo cargado'),
      },
      error: (_, _) => (g.danger, 'Servicio de predicción sin conexión'),
      loading: () => (g.textFaint, 'Conectando con el servicio'),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$texto · $_host',
              style: GavText.muted(context, size: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de la comparación: ↑ INCREMENTO / ↓ DISMINUCIÓN / → ESTABLE / SIN BASE.
class BadgeTendencia extends StatelessWidget {
  const BadgeTendencia(this.comparacion, {super.key});
  final Comparacion comparacion;

  @override
  Widget build(BuildContext context) {
    final pct = comparacion.variacionPorcentual;
    final t = comparacion.tendencia;
    if (pct != null && (t == Tendencia.incremento || t == Tendencia.disminucion)) {
      return GavVariationBadge(pct);
    }
    final g = context.gav;
    final valor = pct == null ? '—' : '→ ${formatearPorcentaje(pct)}';
    final etiqueta = t == Tendencia.sinBase ? 'SIN BASE' : 'ESTABLE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: g.neutralChip, borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valor, style: GavText.strong(context, size: 13).copyWith(color: g.onNeutralChip)),
          Text(etiqueta, style: GavText.label(context).copyWith(color: g.onNeutralChip, fontSize: 8.5)),
        ],
      ),
    );
  }
}

/// Fila "Septiembre · 561 predichas · 530 en 2026 · ↑ +5,8%" (mockups 04 y 06).
class FilaMesPrediccion extends StatelessWidget {
  const FilaMesPrediccion({
    super.key,
    required this.mes,
    required this.anioBase,
    this.destacado = false,
    this.ultima = false,
    this.onTap,
  });

  final MesPrediccion mes;
  final int anioBase;
  final bool destacado;
  final bool ultima;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pred = mes.predichas;
    final base = mes.realesBase;
    final detalle = pred == null
        ? 'Fuera del horizonte del modelo'
        : base == null
            ? '${Fmt.miles(pred)} predichas · sin dato real $anioBase'
            : '${Fmt.miles(pred)} predichas · ${Fmt.miles(base)} en $anioBase';
    final variacion = (pred == null || base == null) ? null : Fmt.variacion(pred, base);

    return InkWell(
      onTap: pred == null ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        decoration: BoxDecoration(
          border: ultima ? null : Border(bottom: BorderSide(color: context.gav.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Fmt.mes(mes.periodo.mes),
                    style: destacado
                        ? GavText.strong(context, size: 15)
                        : GavText.body(context, size: 15, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(detalle, style: GavText.muted(context, size: 12)),
                ],
              ),
            ),
            if (pred != null) GavVariationText(variacion, size: 14),
          ],
        ),
      ),
    );
  }
}

/// "Red neuronal artificial (RNA) v1.0.0 · MAE 16 · RMSE 21 solicitudes por mes"
String notaModelo(ModeloResumen m) =>
    'Red neuronal artificial (RNA) v${m.version} · MAE ${m.mae.round()} · '
    'RMSE ${m.rmse.round()} solicitudes por mes';

/// "Octubre 2027" a partir de un periodo de un mes, o la etiqueta del servicio para rangos.
String tituloPeriodo(PeriodoObjetivo o) =>
    o.esUnMes ? '${Fmt.mes(o.desde.mes)} ${o.desde.anio}' : o.etiqueta;

String tituloBase(PeriodoBase b) =>
    b.desde == b.hasta ? '${Fmt.mes(b.desde.mes).toLowerCase()} ${b.desde.anio}' : b.etiqueta;
