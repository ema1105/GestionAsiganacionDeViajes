import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/lugares/lugares.dart';
import '../../../../core/lugares/ruta_viaje.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/controllers/sesion_controller.dart';
import '../../../notificaciones/data/notificaciones_repository.dart';
import '../../data/cliente_repository.dart';
import '../../data/viajes_cliente_repository_impl.dart';
import '../../domain/entities/viaje.dart';
import '../controllers/viajes_cliente_providers.dart';
import '../widgets/viaje_widgets.dart';

/// Cliente · Inicio: viaje activo o CTA para solicitar, resumen y lugares populares.
class InicioClientePage extends ConsumerWidget {
  const InicioClientePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionControllerProvider).value;
    final activo = ref.watch(viajeActivoClienteProvider);
    final resumen = ref.watch(resumenClienteProvider);
    final populares = ref.watch(lugaresPopularesProvider);
    final noLeidas = ref.watch(notificacionesNoLeidasProvider).value ?? 0;

    return GavPage(
      onRefresh: () async {
        ref
          ..invalidate(resumenClienteProvider)
          ..invalidate(lugaresPopularesProvider)
          ..invalidate(notificacionesNoLeidasProvider)
          ..invalidate(viajeActivoClienteProvider);
        await ref.read(viajeActivoClienteProvider.future);
      },
      children: [
        GavTopBar(
          eyebrow: 'GAV · Cliente',
          title: 'Hola, ${sesion?.nombreUsuario ?? ''}',
          subtitle: '¿A dónde vamos hoy?',
          trailing: GavIconButton(
            icon: Icons.notifications_none,
            badge: noLeidas > 0,
            tooltip: 'Notificaciones',
            onTap: () => context.push('/cliente/notificaciones'),
          ),
        ),
        AsyncValueView<Viaje?>(
          value: activo,
          onRetry: () => ref.invalidate(viajeActivoClienteProvider),
          isEmpty: (v) => v == null,
          empty: _SolicitarCard(onTap: () => context.push('/cliente/solicitar')),
          data: (v) => _ViajeActivoCard(viaje: v!),
        ),
        const SizedBox(height: 4),
        AsyncValueView<ResumenCliente>(
          value: resumen,
          onRetry: () => ref.invalidate(resumenClienteProvider),
          data: (r) => GavKpiGrid(
            children: [
              GavKpiCard(label: 'Viajes realizados', value: '${r.viajesFinalizados}'),
              GavKpiCard(
                label: 'Mi calificación',
                value: r.promedio.promedio == null
                    ? '—'
                    : '★ ${r.promedio.promedio!.toStringAsFixed(1).replaceAll('.', ',')}',
              ),
            ],
          ),
        ),
        const GavSectionTitle('Destinos más solicitados'),
        AsyncValueView<List<LugarPopular>>(
          value: populares,
          onRetry: () => ref.invalidate(lugaresPopularesProvider),
          isEmpty: (l) => l.isEmpty,
          empty: Text('Aún no hay datos de destinos.', style: GavText.muted(context)),
          data: (lista) => Column(
            children: [
              for (final l in lista)
                GavQuickAccessCard(
                  icon: _iconoCategoria(l.categoria),
                  title: l.nombre,
                  subtitle: '${l.totalViajes} viaje${l.totalViajes == 1 ? '' : 's'} solicitados',
                  onTap: activo.value != null
                      ? null
                      : () => context.push('/cliente/solicitar', extra: l.nombre),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconoCategoria(String c) =>
      Lugares.todos.firstWhere((l) => l.categoria == c, orElse: () => Lugares.todos.last).icono;
}

class _SolicitarCard extends StatelessWidget {
  const _SolicitarCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GavCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GavIconBox(icon: Icons.local_taxi_outlined, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sin viaje activo', style: GavText.strong(context, size: 15)),
                      const SizedBox(height: 2),
                      Text('Pide un vehículo y sigue tu viaje en tiempo real.',
                          style: GavText.muted(context, size: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GavPrimaryButton(label: 'Solicitar viaje', onPressed: onTap),
          ],
        ),
      );
}

class _ViajeActivoCard extends ConsumerStatefulWidget {
  const _ViajeActivoCard({required this.viaje});
  final Viaje viaje;

  @override
  ConsumerState<_ViajeActivoCard> createState() => _ViajeActivoCardState();
}

class _ViajeActivoCardState extends ConsumerState<_ViajeActivoCard> {
  bool _cancelando = false;

  Future<void> _cancelar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: const Text('¿Seguro que quieres cancelar este viaje?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _cancelando = true);
    try {
      await ref.read(viajesClienteRepositoryProvider).cancelar(widget.viaje.id);
      ref.invalidate(viajeActivoClienteProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.viaje;
    final g = context.gav;
    return GavCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('VIAJE ACTIVO', style: GavText.label(context)),
              const Spacer(),
              EstadoViajeChip(v.estado),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(v.ruta, style: GavText.strong(context, size: 15))),
              Text(Fmt.pesos(v.precio), style: GavText.strong(context, size: 15).copyWith(color: g.success)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            v.tieneConductor
                ? 'Conductor: ${v.conductorNombre} · ${v.cantidadPasajeros} pasajero${v.cantidadPasajeros == 1 ? '' : 's'}'
                : 'Buscando conductor… · ${v.cantidadPasajeros} pasajero${v.cantidadPasajeros == 1 ? '' : 's'}',
            style: GavText.muted(context, size: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (v.estado.clientePuedeCancelar)
                Expanded(
                  child: GavButton(
                    label: _cancelando ? 'Cancelando…' : 'Cancelar',
                    expand: true,
                    onPressed: _cancelando ? null : _cancelar,
                  ),
                ),
              if (v.estado.clientePuedeCancelar && v.estado.enProceso) const SizedBox(width: 10),
              if (v.estado.enProceso)
                Expanded(
                  child: GavButton(
                    label: 'Seguir viaje',
                    kind: GavButtonKind.gold,
                    expand: true,
                    onPressed: () => context.push('/cliente/seguimiento/${v.id}'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
