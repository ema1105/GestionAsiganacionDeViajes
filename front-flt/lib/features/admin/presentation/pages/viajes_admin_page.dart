import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/lugares/ruta_viaje.dart';
import '../../../../core/pagination/pagina.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../viajes_cliente/domain/entities/estado_viaje.dart';
import '../../../viajes_cliente/domain/entities/viaje.dart';
import '../../../viajes_cliente/presentation/widgets/viaje_widgets.dart';
import '../admin_providers.dart';

/// Filtro "Todos" = null.
enum _Filtro { todos, buscando, aceptados, enCurso, finalizados, cancelados }

extension on _Filtro {
  EstadoViaje? get estado => switch (this) {
        _Filtro.todos => null,
        _Filtro.buscando => EstadoViaje.buscandoConductor,
        _Filtro.aceptados => EstadoViaje.aceptado,
        _Filtro.enCurso => EstadoViaje.enCurso,
        _Filtro.finalizados => EstadoViaje.finalizado,
        _Filtro.cancelados => EstadoViaje.cancelado,
      };
}

/// Mockup admin 09 · Viajes.
class ViajesAdminPage extends ConsumerStatefulWidget {
  const ViajesAdminPage({super.key});

  @override
  ConsumerState<ViajesAdminPage> createState() => _ViajesAdminPageState();
}

class _ViajesAdminPageState extends ConsumerState<ViajesAdminPage> {
  _Filtro _filtro = _Filtro.todos;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final consulta = ConsultaViajes(_filtro.estado, _page);
    final async = ref.watch(viajesAdminProvider(consulta));

    return GavPage(
      onRefresh: () => ref.refresh(viajesAdminProvider(consulta).future),
      children: [
        GavTopBar(eyebrow: 'GAV · Admin', title: 'Viajes', onBack: () => context.pop()),
        GavFilterChips<_Filtro>(
          options: const {
            _Filtro.todos: 'Todos',
            _Filtro.buscando: 'Buscando',
            _Filtro.aceptados: 'Aceptados',
            _Filtro.enCurso: 'En curso',
            _Filtro.finalizados: 'Finalizados',
            _Filtro.cancelados: 'Cancelados',
          },
          selected: _filtro,
          onChanged: (f) => setState(() {
            _filtro = f;
            _page = 0;
          }),
        ),
        const SizedBox(height: 14),
        AsyncValueView<Pagina<Viaje>>(
          value: async,
          onRetry: () => ref.invalidate(viajesAdminProvider(consulta)),
          isEmpty: (p) => p.items.isEmpty,
          empty: const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyView(mensaje: 'No hay viajes con este filtro', icono: Icons.route_outlined),
          ),
          data: (p) => Column(
            children: [
              for (final v in p.items)
                GavCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Viaje #${v.id} · ${v.clienteNombre ?? 'Cliente'}\n${v.ruta}',
                              style: GavText.strong(context, size: 14),
                            ),
                          ),
                          EstadoViajeChip(v.estado),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Conductor: ${v.tieneConductor ? v.conductorNombre : 'sin asignar'} · '
                        '${Fmt.pesos(v.precio)} · ${Fmt.fechaCorta(v.solicitadoEn)}',
                        style: GavText.muted(context, size: 12),
                      ),
                    ],
                  ),
                ),
              GavPaginationFooter(
                text: 'Mostrando ${p.items.length} de ${p.totalElements} viajes',
                onPrev: p.page > 0 ? () => setState(() => _page--) : null,
                onNext: p.isLast ? null : () => setState(() => _page++),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
