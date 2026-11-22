import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_colors.dart';
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
          // Solo se registran conductores (con su vehículo) desde el admin;
          // los clientes crean su cuenta desde la app.
          trailing: _tab == _Tab.clientes
              ? null
              : GavIconButton(
                  icon: Icons.add,
                  gold: true,
                  tooltip: 'Registrar conductor y vehículo',
                  onTap: () => context.push<bool>('/admin/flota/nuevo'),
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
        data: (lista) {
          final inactivos = lista.where((c) => !c.activo).length;
          final activos = lista.length - inactivos;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Conteo(
                '$activos conductor${activos == 1 ? '' : 'es'} activo${activos == 1 ? '' : 's'}'
                '${inactivos > 0 ? ' · $inactivos deshabilitado${inactivos == 1 ? '' : 's'}' : ''}',
              ),
              for (final c in lista) _FilaConductor(conductor: c),
            ],
          );
        },
      );
}

/// Conductor con acción Deshabilitar / Habilitar
/// (POST /api/admin/conductores/{id}/deshabilitar | /habilitar).
class _FilaConductor extends ConsumerStatefulWidget {
  const _FilaConductor({required this.conductor});
  final ConductorAdmin conductor;

  @override
  ConsumerState<_FilaConductor> createState() => _FilaConductorState();
}

class _FilaConductorState extends ConsumerState<_FilaConductor> {
  bool _procesando = false;

  Future<void> _cambiarEstado() async {
    final c = widget.conductor;
    final deshabilitar = c.activo;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(deshabilitar ? 'Deshabilitar conductor' : 'Habilitar conductor'),
        content: Text(
          deshabilitar
              ? '${c.nombre} dejará de recibir viajes y no podrá iniciar sesión. '
                  'Su historial, ganancias y reseñas se conservan, y puedes habilitarlo de nuevo cuando quieras.'
              : '${c.nombre} podrá iniciar sesión y volverá a la cola para recibir viajes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(deshabilitar ? 'Sí, deshabilitar' : 'Sí, habilitar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _procesando = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      if (deshabilitar) {
        await repo.deshabilitarConductor(c.id);
      } else {
        await repo.habilitarConductor(c.id);
      }
      // Cambia el conteo de disponibles del inicio y la lista de conductores.
      ref
        ..invalidate(conductoresAdminProvider)
        ..invalidate(resumenInicioProvider);
      if (mounted) {
        showInfoSnack(context, deshabilitar ? '${c.nombre} fue deshabilitado.' : '${c.nombre} fue habilitado.');
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conductor;
    final g = context.gav;
    return Opacity(
      opacity: c.activo ? 1 : 0.6,
      child: _FilaPersona(
        nombre: c.nombre,
        detalle: [
          if ((c.vehiculo ?? '').isNotEmpty) c.vehiculo!,
          if ((c.placa ?? '').isNotEmpty) c.placa!,
        ].join(' · ').ifEmpty('Sin vehículo asignado'),
        extra: c.licencia == null ? null : 'Licencia ${c.licencia}',
        chip: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            !c.activo
                ? const GavChip('Deshabilitado', kind: GavChipKind.danger, upper: false)
                : c.disponible
                    ? const GavChip('Disponible', upper: false)
                    : const GavChip('En viaje', kind: GavChipKind.success, upper: false),
            const SizedBox(width: 6),
            if (_procesando)
              const SizedBox.square(
                dimension: 40,
                child: Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: c.activo ? 'Deshabilitar' : 'Habilitar',
                onPressed: _cambiarEstado,
                icon: Icon(
                  c.activo ? Icons.person_off_outlined : Icons.how_to_reg_outlined,
                  size: 20,
                  color: c.activo ? g.danger : g.gold,
                ),
              ),
          ],
        ),
      ),
    );
  }
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
