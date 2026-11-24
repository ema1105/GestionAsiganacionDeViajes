import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:material_ui/material_ui.dart';

import '../../../../core/location/ubicacion.dart';
import '../../../../core/lugares/ruta_viaje.dart';
import '../../../../core/maps/gav_mapa.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../notificaciones/data/notificaciones_repository.dart';
import '../../../viajes_cliente/domain/entities/viaje.dart';
import '../../../viajes_cliente/presentation/widgets/viaje_widgets.dart';
import '../../data/conductor_repository_impl.dart';
import '../../domain/conductor_models.dart';
import '../../domain/solicitud_pendiente.dart';
import '../controllers/conductor_providers.dart';
import '../controllers/rastreo_conductor.dart';
import '../widgets/acciones_viaje.dart';

/// Mockup conductor 02 · Panel.
class PanelConductorPage extends ConsumerWidget {
  const PanelConductorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilConductorProvider);
    final activo = ref.watch(viajeActivoConductorProvider);
    final noLeidas = ref.watch(notificacionesNoLeidasProvider).value ?? 0;

    return GavPage(
      onRefresh: () async {
        ref
          ..invalidate(perfilConductorProvider)
          ..invalidate(solicitudPendienteProvider)
          ..invalidate(notificacionesNoLeidasProvider)
          ..invalidate(viajeActivoConductorProvider);
        await ref.read(viajeActivoConductorProvider.future);
      },
      children: [
        GavTopBar(
          eyebrow: 'GAV · Conductor',
          title: 'Panel',
          subtitle: 'Tu viaje activo y solicitudes entrantes',
          trailing: GavIconButton(
            icon: Icons.notifications_none,
            badge: noLeidas > 0,
            tooltip: 'Notificaciones',
            onTap: () => context.push('/conductor/notificaciones'),
          ),
        ),
        AsyncValueView<PerfilConductor>(
          value: perfil,
          onRetry: () => ref.invalidate(perfilConductorProvider),
          data: (p) => _VehiculoAsignadoCard(perfil: p),
        ),
        const _UbicacionCard(),
        AsyncValueView<Viaje?>(
          value: activo,
          onRetry: () => ref.invalidate(viajeActivoConductorProvider),
          isEmpty: (v) => v == null,
          empty: const _SinViajeActivo(),
          data: (v) => _ViajeActivoCard(viaje: v!),
        ),
        // Solo se escuchan ofertas cuando no hay viaje en curso.
        if (activo.value == null && !activo.isLoading) ...[
          const GavSectionTitle('Solicitudes entrantes'),
          const _SolicitudesEntrantes(),
        ],
      ],
    );
  }
}

class _VehiculoAsignadoCard extends StatelessWidget {
  const _VehiculoAsignadoCard({required this.perfil});
  final PerfilConductor perfil;

  @override
  Widget build(BuildContext context) => GavCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VEHÍCULO ASIGNADO', style: GavText.label(context)),
            const SizedBox(height: 12),
            Row(
              children: [
                const GavIconBox(icon: Icons.directions_car_filled_outlined, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: perfil.tieneVehiculo
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(perfil.vehiculo, style: GavText.strong(context, size: 15)),
                            const SizedBox(height: 3),
                            Text(
                              'Placa ${perfil.placaVehiculo} · ${perfil.capacidad} pasajeros'
                              '${perfil.categoriaVehiculo != null ? ' · Categoría ${perfil.categoriaVehiculo}' : ''}',
                              style: GavText.muted(context, size: 12),
                            ),
                          ],
                        )
                      : Text(
                          'Sin vehículo asignado. Contacta al administrador.',
                          style: GavText.muted(context, size: 12.5),
                        ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _SinViajeActivo extends StatelessWidget {
  const _SinViajeActivo();

  @override
  Widget build(BuildContext context) => GavCard(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: context.gav.goldContainer, shape: BoxShape.circle),
                child: Icon(Icons.schedule, size: 19, color: context.gav.gold),
              ),
              const SizedBox(height: 12),
              Text('Sin viaje activo', style: GavText.strong(context, size: 15)),
              const SizedBox(height: 4),
              Text(
                'Estás en la cola FIFO. Recibirás una solicitud pronto.',
                textAlign: TextAlign.center,
                style: GavText.muted(context, size: 12),
              ),
            ],
          ),
        ),
      );
}

class _SolicitudesEntrantes extends ConsumerWidget {
  const _SolicitudesEntrantes();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView<SolicitudPendiente?>(
        value: ref.watch(solicitudPendienteProvider),
        onRetry: () => ref.invalidate(solicitudPendienteProvider),
        isEmpty: (s) => s == null,
        empty: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('No hay solicitudes por ahora.', style: GavText.muted(context)),
        ),
        data: (s) => _SolicitudCard(solicitud: s!),
      );
}

class _SolicitudCard extends ConsumerStatefulWidget {
  const _SolicitudCard({required this.solicitud});
  final SolicitudPendiente solicitud;

  @override
  ConsumerState<_SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends ConsumerState<_SolicitudCard> {
  bool _enviando = false;

  Future<void> _responder(bool aceptar) async {
    setState(() => _enviando = true);
    try {
      await ref.read(conductorRepositoryProvider).responder(widget.solicitud.viajeId, aceptar: aceptar);
      ref
        ..invalidate(solicitudPendienteProvider)
        ..invalidate(viajeActivoConductorProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.solicitud;
    final cliente = s.clienteNombre ?? 'Cliente';
    return GavCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Viaje #${s.viajeId} · ${rutaDe(s.origen, s.destino, origenNombre: s.origenNombre, destinoNombre: s.destinoNombre)}', style: GavText.strong(context, size: 14)),
              ),
              Text(
                Fmt.pesos(s.precio),
                style: GavText.strong(context, size: 14).copyWith(color: context.gav.success),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${s.expiraEn != null ? 'Responde antes de las ${Fmt.hora(s.expiraEn)}' : 'Nueva solicitud'}'
            ' · $cliente · ${s.cantidadPasajeros} pasajero${s.cantidadPasajeros == 1 ? '' : 's'}',
            style: GavText.muted(context, size: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GavButton(
                  label: 'Rechazar',
                  expand: true,
                  onPressed: _enviando ? null : () => _responder(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GavButton(
                  label: 'Aceptar',
                  kind: GavButtonKind.gold,
                  expand: true,
                  onPressed: _enviando ? null : () => _responder(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViajeActivoCard extends ConsumerStatefulWidget {
  const _ViajeActivoCard({required this.viaje});
  final Viaje viaje;

  @override
  ConsumerState<_ViajeActivoCard> createState() => _ViajeActivoCardState();
}

class _ViajeActivoCardState extends ConsumerState<_ViajeActivoCard> {
  bool _enviando = false;

  Future<void> _ejecutar(AccionConductor accion) async {
    setState(() => _enviando = true);
    // Mismo flujo que la pestaña "Viaje": confirma, ejecuta y, al finalizar, abre la calificación del cliente.
    await ejecutarAccionConductor(context, ref, accion, widget.viaje);
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.viaje;
    final accion = AccionConductor.siguiente(v.estado);
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
              Expanded(
                child: Text(
                  v.ruta,
                  style: GavText.strong(context, size: 15),
                ),
              ),
              Text(Fmt.pesos(v.precio),
                  style: GavText.strong(context, size: 15).copyWith(color: context.gav.success)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${v.cantidadPasajeros} pasajero${v.cantidadPasajeros == 1 ? '' : 's'} · Solicitado ${Fmt.fechaCorta(v.solicitadoEn)}',
            style: GavText.muted(context, size: 12),
          ),
          const SizedBox(height: 12),
          GavMapa(
            height: 180,
            origen: LatLng(v.origen.lat, v.origen.lng),
            destino: LatLng(v.destino.lat, v.destino.lng),
            conductor: _miPosicion(ref),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go('/conductor/viaje'),
              icon: const Icon(Icons.open_in_full, size: 16),
              label: const Text('Ver detalle del viaje'),
            ),
          ),
          if (accion != null) ...[
            const SizedBox(height: 4),
            GavButton(
              label: _enviando ? 'Enviando…' : accion.etiqueta,
              kind: GavButtonKind.gold,
              expand: true,
              onPressed: _enviando ? null : () => _ejecutar(accion),
            ),
          ],
        ],
      ),
    );
  }
}

LatLng? _miPosicion(WidgetRef ref) {
  final r = ref.watch(rastreoConductorProvider);
  return r.lat == null || r.lng == null ? null : LatLng(r.lat!, r.lng!);
}

/// Estado del GPS del conductor. Pide el permiso al abrir el panel.
class _UbicacionCard extends ConsumerStatefulWidget {
  const _UbicacionCard();

  @override
  ConsumerState<_UbicacionCard> createState() => _UbicacionCardState();
}

class _UbicacionCardState extends ConsumerState<_UbicacionCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final r = ref.read(rastreoConductorProvider);
      if (!r.activo && r.permiso == null) ref.read(rastreoConductorProvider.notifier).activar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(rastreoConductorProvider);
    final g = context.gav;
    final activo = r.activo;
    final texto = activo
        ? (r.ultimoEnvio == null
            ? 'Obteniendo tu posición…'
            : 'Compartiendo ubicación · último envío ${Fmt.hora(r.ultimoEnvio)}')
        : (r.permiso?.mensaje ?? 'Activa tu ubicación para recibir solicitudes cercanas.');

    return GavCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GavIconBox(
            icon: activo ? Icons.my_location : Icons.location_disabled_outlined,
            color: activo ? g.success : g.danger,
            background: activo ? g.successContainer : g.dangerContainer,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activo ? 'GPS activo' : 'GPS inactivo', style: GavText.strong(context, size: 13.5)),
                const SizedBox(height: 2),
                Text(r.error ?? texto, style: GavText.muted(context, size: 11.5)),
              ],
            ),
          ),
          if (!activo && r.permiso != EstadoPermiso.denegadoPermanente)
            GavButton(
              label: 'Activar',
              kind: GavButtonKind.gold,
              height: 36,
              onPressed: () => ref.read(rastreoConductorProvider.notifier).activar(),
            ),
        ],
      ),
    );
  }
}