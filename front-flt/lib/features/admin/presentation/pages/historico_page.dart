import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../prediccion/domain/periodo.dart';
import '../../../prediccion/domain/prediccion.dart';
import '../../../prediccion/presentation/prediccion_providers.dart';
import '../../../prediccion/presentation/widgets/graficas_prediccion.dart';
import '../../../prediccion/presentation/widgets/prediccion_widgets.dart';

/// Mockup admin 06 · Histórico: predicción del año contra lo real del año anterior.
///
/// Cada año se consulta como `mes=1` del año: `otros_meses` trae enero a diciembre.
class HistoricoPage extends ConsumerStatefulWidget {
  const HistoricoPage({super.key});

  @override
  ConsumerState<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends ConsumerState<HistoricoPage> {
  static const _porPagina = 6;

  int? _anio;
  int _pagina = 0;

  void _refrescar() => ref
    ..invalidate(fichaModeloProvider)
    ..invalidate(prediccionProvider);

  @override
  Widget build(BuildContext context) {
    final ficha = ref.watch(fichaModeloProvider);

    return GavPage(
      onRefresh: () async {
        _refrescar();
        await ref.read(fichaModeloProvider.future);
      },
      children: [
        const GavTopBar(title: 'Histórico', subtitle: 'Predicción vs. real por mes'),
        AsyncValueView<FichaModelo>(
          value: ficha,
          onRetry: _refrescar,
          data: _contenido,
        ),
      ],
    );
  }

  Widget _contenido(FichaModelo f) {
    // Años con predicción: del último dato real hasta el final del horizonte.
    final anios = [for (var a = f.ultimoMesReal.anio; a <= f.horizonteHasta.anio; a++) a];
    final anio = anios.contains(_anio) ? _anio! : anios.last;
    final async = ref.watch(prediccionProvider(Periodo(anio, 1)));
    final destacado = periodoActivo(f, ref.watch(periodoSeleccionadoProvider));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GavSegmented<int>(
            options: {for (final a in anios) a: '$a'},
            selected: anio,
            onChanged: (a) => setState(() {
              _anio = a;
              _pagina = 0;
            }),
          ),
        ),
        const SizedBox(height: 14),
        AsyncValueView<Prediccion>(
          value: async,
          onRetry: () => ref.invalidate(prediccionProvider(Periodo(anio, 1))),
          isEmpty: (p) => p.meses.isEmpty,
          empty: const EmptyView(mensaje: 'Sin datos para este año', icono: Icons.history),
          data: (p) => _Anio(
            prediccion: p,
            anio: anio,
            destacado: destacado,
            pagina: _pagina,
            porPagina: _porPagina,
            onPagina: (n) => setState(() => _pagina = n),
            onElegir: (periodo) {
              ref.read(periodoSeleccionadoProvider.notifier).elegir(periodo);
              context.go('/admin/prediccion');
            },
          ),
        ),
      ],
    );
  }
}

class _Anio extends StatelessWidget {
  const _Anio({
    required this.prediccion,
    required this.anio,
    required this.destacado,
    required this.pagina,
    required this.porPagina,
    required this.onPagina,
    required this.onElegir,
  });

  final Prediccion prediccion;
  final int anio;
  final Periodo destacado;
  final int pagina;
  final int porPagina;
  final ValueChanged<int> onPagina;
  final ValueChanged<Periodo> onElegir;

  @override
  Widget build(BuildContext context) {
    final meses = [...prediccion.meses]..sort((a, b) => a.periodo.compareTo(b.periodo));
    final anioBase = prediccion.base.desde.anio;

    final velas = [
      for (final m in meses)
        if (m.predichas != null)
          VelaMes(
            etiqueta: Fmt.mesCorto(m.periodo.mes),
            apertura: m.realesBase,
            cierre: m.predichas!,
            // Sin intervalo (servicio anterior): la mecha cubre solo el cuerpo.
            minimo: m.intervalo?.min ?? _menor(m.predichas!, m.realesBase),
            maximo: m.intervalo?.max ?? _mayor(m.predichas!, m.realesBase),
          ),
    ];

    final paginas = (meses.length / porPagina).ceil();
    final actual = pagina.clamp(0, paginas == 0 ? 0 : paginas - 1);
    final visibles = meses.skip(actual * porPagina).take(porPagina).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GavCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tendencia anual · velas', style: GavText.strong(context, size: 14)),
              const SizedBox(height: 2),
              Text(
                'Base $anioBase · predicho $anio · rango',
                style: GavText.muted(context, size: 11.5),
              ),
              const SizedBox(height: 12),
              if (velas.isEmpty)
                const EmptyView(mensaje: 'El modelo aún no predice meses de este año')
              else
                LienzoGrafica(height: 150, painter: VelasPainter(velas)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 2),
          child: Row(
            children: [
              Expanded(child: Text('MES', style: GavText.label(context))),
              Text('PREDICHO · VARIACIÓN', style: GavText.label(context)),
            ],
          ),
        ),
        for (var i = 0; i < visibles.length; i++)
          FilaMesPrediccion(
            mes: visibles[i],
            anioBase: anioBase,
            destacado: visibles[i].periodo == destacado,
            ultima: i == visibles.length - 1,
            onTap: () => onElegir(visibles[i].periodo),
          ),
        const SizedBox(height: 8),
        GavPaginationFooter(
          text: 'Mostrando ${visibles.length} de ${meses.length} meses',
          onPrev: actual > 0 ? () => onPagina(actual - 1) : null,
          onNext: actual < paginas - 1 ? () => onPagina(actual + 1) : null,
        ),
        const SizedBox(height: 12),
        Text(notaModelo(prediccion.modelo), style: GavText.muted(context, size: 12)),
      ],
    );
  }

  static int _menor(int a, int? b) => b == null || a < b ? a : b;
  static int _mayor(int a, int? b) => b == null || a > b ? a : b;
}
