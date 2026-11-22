import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/lugares/ruta_viaje.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../controllers/conductor_providers.dart';

/// Mockup conductor 05 · Ganancias.
class GananciasPage extends ConsumerWidget {
  const GananciasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(resumenGananciasProvider);
    return GavPage(
      onRefresh: () => ref.refresh(resumenGananciasProvider.future),
      children: [
        const GavTopBar(
          eyebrow: 'GAV · Conductor',
          title: 'Ganancias',
          subtitle: 'Tus ingresos y viajes en la plataforma',
        ),
        AsyncValueView<ResumenGanancias>(
          value: async,
          onRetry: () => ref.invalidate(resumenGananciasProvider),
          data: (r) {
            final hoy = DateTime.now();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GavKpiGrid(
                  children: [
                    GavKpiCard(label: 'Ganancia del día', value: Fmt.pesos(r.hoy.total)),
                    GavKpiCard(label: 'Ganancia del mes', value: Fmt.pesos(r.mes.total)),
                    GavKpiCard(label: 'Viajes del día', value: '${r.hoy.viajes}'),
                    GavKpiCard(label: 'Viajes del mes', value: '${r.mes.viajes}'),
                  ],
                ),
                GavCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumen de hoy', style: GavText.strong(context, size: 14.5)),
                      const SizedBox(height: 8),
                      Text(
                        '${Fmt.fechaLarga(hoy)} · Realizaste ${r.hoy.viajes} '
                        'viaje${r.hoy.viajes == 1 ? '' : 's'} y generaste ${Fmt.pesos(r.hoy.total)}. '
                        'En el mes acumulas ${Fmt.pesos(r.mes.total)} en ${r.mes.viajes} '
                        'viaje${r.mes.viajes == 1 ? '' : 's'}.',
                        style: GavText.muted(context, size: 12.5),
                      ),
                    ],
                  ),
                ),
                GavCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Últimos pagos', style: GavText.strong(context, size: 14.5)),
                      const SizedBox(height: 6),
                      if (r.ultimosPagos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Aún no tienes viajes finalizados.', style: GavText.muted(context)),
                        ),
                      for (final v in r.ultimosPagos)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  v.ruta,
                                  style: GavText.body(context, size: 13.5),
                                ),
                              ),
                              Text(
                                '+${Fmt.pesos(v.precio)}',
                                style: GavText.strong(context, size: 13.5).copyWith(color: context.gav.success),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
