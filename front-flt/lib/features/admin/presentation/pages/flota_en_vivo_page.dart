import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/admin_repository.dart';
import '../admin_providers.dart';
import '../widgets/mapa_flota.dart';

enum _FiltroFlota { todos, disponibles, enViaje }

/// Admin · Flota en vivo: mapa con los conductores conectados (sesión abierta y
/// señal GPS en los últimos 30 s). Se actualiza cada 10 s.
class FlotaEnVivoPage extends ConsumerStatefulWidget {
  const FlotaEnVivoPage({super.key});

  @override
  ConsumerState<FlotaEnVivoPage> createState() => _FlotaEnVivoPageState();
}

class _FlotaEnVivoPageState extends ConsumerState<FlotaEnVivoPage> {
  _FiltroFlota _filtro = _FiltroFlota.todos;
  int? _seleccionado;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(flotaEnVivoProvider);

    return GavPage(
      onRefresh: () async {
        ref.invalidate(flotaEnVivoProvider);
        await ref.read(flotaEnVivoProvider.future);
      },
      children: [
        GavTopBar(
          eyebrow: 'GAV · Admin',
          title: 'Flota en vivo',
          subtitle: 'Conductores conectados ahora · se actualiza cada 10 s',
          trailing: GavIconButton(
            icon: Icons.refresh,
            tooltip: 'Actualizar',
            onTap: () => ref.invalidate(flotaEnVivoProvider),
          ),
        ),
        AsyncValueView<FlotaSnapshot>(
          value: async,
          onRetry: () => ref.invalidate(flotaEnVivoProvider),
          data: _contenido,
        ),
      ],
    );
  }

  Widget _contenido(FlotaSnapshot s) {
    final todos = s.conductores;
    final enViaje = todos.where((c) => c.enViaje).length;
    final disponibles = todos.length - enViaje;
    final visibles = switch (_filtro) {
      _FiltroFlota.todos => todos,
      _FiltroFlota.disponibles => todos.where((c) => !c.enViaje).toList(),
      _FiltroFlota.enViaje => todos.where((c) => c.enViaje).toList(),
    };

    return LayoutBuilder(
      builder: (context, box) {
        final ancho = box.maxWidth >= 900;
        final mapa = MapaFlota(
          conductores: visibles,
          seleccionadoId: _seleccionado,
          onSeleccionar: (id) => setState(() => _seleccionado = id),
          height: ancho ? 560 : 320,
        );
        final lista = _ListaConductores(
          conductores: visibles,
          seleccionadoId: _seleccionado,
          onSeleccionar: (id) => setState(() => _seleccionado = id),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EnVivoChip(hora: s.recibidoEn),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: GavKpiCard(label: 'Conectados', value: '${todos.length}')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GavKpiCard(label: 'Disponibles', value: '$disponibles', valueColor: context.gav.success),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: GavKpiCard(label: 'En viaje', value: '$enViaje', valueColor: context.gav.gold)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GavFilterChips<_FiltroFlota>(
              options: {
                _FiltroFlota.todos: 'Todos · ${todos.length}',
                _FiltroFlota.disponibles: 'Disponibles · $disponibles',
                _FiltroFlota.enViaje: 'En viaje · $enViaje',
              },
              selected: _filtro,
              onChanged: (f) => setState(() => _filtro = f),
            ),
            const SizedBox(height: 12),
            if (ancho)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: mapa),
                  const SizedBox(width: 16),
                  SizedBox(width: 360, child: lista),
                ],
              )
            else ...[
              mapa,
              const SizedBox(height: 12),
              lista,
            ],
            const SizedBox(height: 10),
            Text(
              'Solo aparecen conductores con sesión abierta y señal en los últimos 30 s. '
              'Al cerrar sesión o ser deshabilitados, desaparecen del mapa.',
              style: GavText.muted(context, size: 11.5),
            ),
          ],
        );
      },
    );
  }
}

class _EnVivoChip extends StatelessWidget {
  const _EnVivoChip({required this.hora});
  final DateTime hora;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final hh = hora.hour.toString().padLeft(2, '0');
    final mm = hora.minute.toString().padLeft(2, '0');
    final ss = hora.second.toString().padLeft(2, '0');
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: g.successContainer, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: g.success, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('EN VIVO · $hh:$mm:$ss', style: GavText.label(context).copyWith(color: g.success)),
          ],
        ),
      ),
    );
  }
}

class _ListaConductores extends StatelessWidget {
  const _ListaConductores({required this.conductores, required this.onSeleccionar, this.seleccionadoId});
  final List<ConductorEnVivo> conductores;
  final int? seleccionadoId;
  final ValueChanged<int> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    if (conductores.isEmpty) {
      return const GavCard(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: EmptyView(mensaje: 'No hay conductores conectados en este momento.', icono: Icons.wifi_off),
      );
    }
    final g = context.gav;
    return Column(
      children: [
        for (final c in conductores)
          GavCard(
            padding: const EdgeInsets.all(12),
            color: c.id == seleccionadoId ? g.surfaceAlt : null,
            onTap: () => onSeleccionar(c.id),
            child: Row(
              children: [
                GavAvatar(c.nombre, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.nombre, style: GavText.strong(context, size: 14)),
                      const SizedBox(height: 2),
                      Text(_detalle(c), style: GavText.muted(context, size: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GavChip(
                  c.enViaje ? 'En viaje' : 'Disponible',
                  kind: c.enViaje ? GavChipKind.warm : GavChipKind.success,
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _detalle(ConductorEnVivo c) {
    final partes = <String>[
      if (c.placa != null) c.placa!,
      if (c.enViaje)
        'Viaje #${c.viajeId}${c.destinoNombre != null ? ' → ${c.destinoNombre}' : ''}'
      else if (c.vehiculo != null && c.vehiculo!.isNotEmpty)
        c.vehiculo!,
      if (c.segundosSinSenal != null) 'hace ${c.segundosSinSenal} s',
    ];
    return partes.join(' · ');
  }
}
