import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/lugares/ruta_viaje.dart';
import '../../../../core/pagination/pagina.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../viajes_cliente/domain/entities/viaje.dart';
import '../../../viajes_cliente/presentation/widgets/viaje_widgets.dart';
import '../controllers/conductor_providers.dart';

/// Mockup conductor 04 · Historial.
class HistorialConductorPage extends ConsumerStatefulWidget {
  const HistorialConductorPage({super.key});

  @override
  ConsumerState<HistorialConductorPage> createState() => _HistorialConductorPageState();
}

class _HistorialConductorPageState extends ConsumerState<HistorialConductorPage> {
  PeriodoHistorial _periodo = PeriodoHistorial.todos;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final consulta = ConsultaHistorial(_periodo, _page);
    final async = ref.watch(historialConductorProvider(consulta));

    return GavPage(
      onRefresh: () => ref.refresh(historialConductorProvider(consulta).future),
      children: [
        const GavTopBar(
          eyebrow: 'GAV · Conductor',
          title: 'Historial',
          subtitle: 'Todos tus viajes realizados en la plataforma',
        ),
        GavFilterChips<PeriodoHistorial>(
          options: const {
            PeriodoHistorial.todos: 'Todos',
            PeriodoHistorial.semana: 'Esta semana',
            PeriodoHistorial.mes: 'Este mes',
          },
          selected: _periodo,
          onChanged: (p) => setState(() {
            _periodo = p;
            _page = 0;
          }),
        ),
        const SizedBox(height: 14),
        AsyncValueView<Pagina<Viaje>>(
          value: async,
          onRetry: () => ref.invalidate(historialConductorProvider(consulta)),
          isEmpty: (p) => p.items.isEmpty,
          empty: const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyView(mensaje: 'No hay viajes en este periodo', icono: Icons.history),
          ),
          data: (p) {
            final totalPaginas = (p.totalElements / tamanoPaginaHistorial).ceil();
            return Column(
              children: [
                for (final v in p.items) ViajeResumenCard(viaje: v),
                GavPaginationFooter(
                  text: 'Mostrando ${p.items.length} de ${p.totalElements} viajes · '
                      'página ${p.page + 1} de ${totalPaginas == 0 ? 1 : totalPaginas}',
                  onPrev: p.page > 0 ? () => setState(() => _page--) : null,
                  onNext: p.isLast ? null : () => setState(() => _page++),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Card de viaje del historial: "Viaje #12 · Cliente   $22.000 / fecha / chip".
class ViajeResumenCard extends StatelessWidget {
  const ViajeResumenCard({super.key, required this.viaje, this.subtitulo});
  final Viaje viaje;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) => GavCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    viaje.ruta,
                    style: GavText.strong(context, size: 14),
                  ),
                ),
                Text(Fmt.pesos(viaje.precio), style: GavText.strong(context, size: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo ??
                  '${Fmt.fechaCorta(viaje.solicitadoEn)} · ${viaje.clienteNombre ?? 'Cliente'}',
              style: GavText.muted(context, size: 12),
            ),
            const SizedBox(height: 10),
            EstadoViajeChip(viaje.estado),
          ],
        ),
      );
}
