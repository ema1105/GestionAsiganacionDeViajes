import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/admin_repository.dart';
import '../admin_providers.dart';

enum _Tab { conductores, vehiculos, clientes }

/// Mockup admin 08 · Flota y clientes.
class FlotaPage extends ConsumerStatefulWidget {
  const FlotaPage({super.key});

  @override
  ConsumerState<FlotaPage> createState() => _FlotaPageState();
}

class _FlotaPageState extends ConsumerState<FlotaPage> {
  _Tab _tab = _Tab.conductores;

  Future<void> _refrescar() async {
    switch (_tab) {
      case _Tab.conductores:
        ref.invalidate(conductoresAdminProvider);
        await ref.read(conductoresAdminProvider.future);
      case _Tab.vehiculos:
        ref.invalidate(vehiculosAdminProvider);
        await ref.read(vehiculosAdminProvider.future);
      case _Tab.clientes:
        ref.invalidate(clientesAdminProvider);
        await ref.read(clientesAdminProvider.future);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GavPage(
      onRefresh: _refrescar,
      children: [
        GavTopBar(
          eyebrow: 'GAV · Admin',
          title: 'Flota y clientes',
          onBack: () => context.pop(),
          trailing: GavIconButton(
            icon: Icons.add,
            gold: true,
            tooltip: 'Agregar',
            onTap: () => showInfoSnack(
              context,
              'El registro de conductores y vehículos se hará desde aquí en la siguiente fase.',
            ),
          ),
        ),
        GavSegmented<_Tab>(
          expand: true,
          options: const {
            _Tab.conductores: 'Conductores',
            _Tab.vehiculos: 'Vehículos',
            _Tab.clientes: 'Clientes',
          },
          selected: _tab,
          onChanged: (t) => setState(() => _tab = t),
        ),
        const SizedBox(height: 14),
        switch (_tab) {
          _Tab.conductores => const _Conductores(),
          _Tab.vehiculos => const _Vehiculos(),
          _Tab.clientes => const _Clientes(),
        },
      ],
    );
  }
}

class _Conductores extends ConsumerWidget {
  const _Conductores();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView<List<ConductorAdmin>>(
        value: ref.watch(conductoresAdminProvider),
        onRetry: () => ref.invalidate(conductoresAdminProvider),
        isEmpty: (l) => l.isEmpty,
        empty: const EmptyView(mensaje: 'No hay conductores registrados'),
        data: (lista) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Conteo('${lista.length} conductor${lista.length == 1 ? '' : 'es'} registrado${lista.length == 1 ? '' : 's'}'),
            for (final c in lista)
              _FilaPersona(
                nombre: c.nombre,
                detalle: [
                  if ((c.vehiculo ?? '').isNotEmpty) c.vehiculo!,
                  if ((c.placa ?? '').isNotEmpty) c.placa!,
                ].join(' · ').ifEmpty('Sin vehículo asignado'),
                extra: c.licencia == null ? null : 'Licencia ${c.licencia}',
                chip: !c.activo
                    ? const GavChip('Deshabilitado', kind: GavChipKind.danger, upper: false)
                    : c.disponible
                        ? const GavChip('Disponible', upper: false)
                        : const GavChip('En viaje', kind: GavChipKind.success, upper: false),
              ),
          ],
        ),
      );
}

class _Vehiculos extends ConsumerWidget {
  const _Vehiculos();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView<List<VehiculoAdmin>>(
        value: ref.watch(vehiculosAdminProvider),
        onRetry: () => ref.invalidate(vehiculosAdminProvider),
        isEmpty: (l) => l.isEmpty,
        empty: const EmptyView(mensaje: 'No hay vehículos registrados'),
        data: (lista) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Conteo('${lista.length} vehículo${lista.length == 1 ? '' : 's'} registrado${lista.length == 1 ? '' : 's'}'),
            for (final v in lista)
              GavCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const GavIconBox(icon: Icons.directions_car_filled_outlined, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.descripcion, style: GavText.strong(context, size: 14)),
                          const SizedBox(height: 2),
                          Text(
                            'Placa ${v.placa} · ${v.capacidad} pasajeros'
                            '${v.categoria != null ? ' · ${v.categoria}' : ''}',
                            style: GavText.muted(context, size: 12),
                          ),
                          if (v.conductor != null) ...[
                            const SizedBox(height: 2),
                            Text('Conductor: ${v.conductor}', style: GavText.muted(context, size: 12)),
                          ],
                        ],
                      ),
                    ),
                    GavChip(
                      v.conductor == null ? 'Libre' : 'Asignado',
                      kind: v.conductor == null ? GavChipKind.neutral : GavChipKind.warm,
                      upper: false,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _Clientes extends ConsumerWidget {
  const _Clientes();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView<List<ClienteAdmin>>(
        value: ref.watch(clientesAdminProvider),
        onRetry: () => ref.invalidate(clientesAdminProvider),
        isEmpty: (l) => l.isEmpty,
        empty: const EmptyView(mensaje: 'No hay clientes registrados'),
        data: (lista) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Conteo('${lista.length} cliente${lista.length == 1 ? '' : 's'} registrado${lista.length == 1 ? '' : 's'}'),
            for (final c in lista)
              _FilaPersona(
                nombre: c.nombre,
                detalle: c.email,
                extra: c.telefono,
                chip: GavChip('${c.totalViajes} viaje${c.totalViajes == 1 ? '' : 's'}', upper: false),
              ),
          ],
        ),
      );
}

class _Conteo extends StatelessWidget {
  const _Conteo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(texto, style: GavText.muted(context, size: 12)),
      );
}

class _FilaPersona extends StatelessWidget {
  const _FilaPersona({required this.nombre, required this.detalle, required this.chip, this.extra});
  final String nombre;
  final String detalle;
  final String? extra;
  final Widget chip;

  @override
  Widget build(BuildContext context) => GavCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GavAvatar(nombre, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: GavText.strong(context, size: 14)),
                  const SizedBox(height: 2),
                  Text(detalle, style: GavText.muted(context, size: 12)),
                  if ((extra ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(extra!, style: GavText.muted(context, size: 11.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            chip,
          ],
        ),
      );
}

extension on String {
  String ifEmpty(String otro) => isEmpty ? otro : this;
}
