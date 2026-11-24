import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:material_ui/material_ui.dart';

import '../../../../core/lugares/lugares.dart';
import '../../../../core/lugares/ruta_viaje.dart';
import '../../../../core/maps/gav_mapa.dart';
import '../../../../core/maps/ruta_calculada.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/viajes_cliente_repository_impl.dart';
import '../../domain/entities/estado_viaje.dart';
import '../../domain/entities/viaje.dart';
import '../controllers/viajes_cliente_providers.dart';
import '../widgets/viaje_widgets.dart';
import 'viajes_cliente_page.dart' show mostrarCalificar;

/// Cliente · Seguimiento en vivo (posición del conductor cada Env.pollingInterval).
/// - Traza la ruta real por calles (origen → destino) y el tramo conductor → punto.
/// - Cuando el viaje termina (FINALIZADO / CANCELADO) muestra el cierre y abre la
///   calificación del conductor, en vez de quedarse "En vivo" sin datos.
class SeguimientoPage extends ConsumerStatefulWidget {
  const SeguimientoPage({super.key, required this.viajeId});
  final int viajeId;

  @override
  ConsumerState<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends ConsumerState<SeguimientoPage> {
  /// Último estado conocido del viaje (se conserva cuando deja de ser "activo").
  Viaje? _viaje;

  /// Viaje ya terminado (FINALIZADO o CANCELADO). Si no es null se muestra el cierre.
  Viaje? _terminado;
  bool _verificando = false;
  bool _calificacionAbierta = false;
  RutaCalculada? _tramo;

  /// El viaje dejó de aparecer como activo: se consulta su estado real.
  Future<void> _verificarFin() async {
    if (_verificando || _terminado != null) return;
    _verificando = true;
    try {
      final v = await ref.read(viajesClienteRepositoryProvider).obtener(widget.viajeId);
      if (!mounted) return;
      if (v.estado.terminado) {
        setState(() => _terminado = v);
        if (v.estado == EstadoViaje.finalizado && v.tieneConductor) _abrirCalificacion(v);
      } else {
        setState(() => _viaje = v);
      }
    } catch (_) {
      // Error transitorio: se reintenta en el próximo ciclo del polling.
    } finally {
      _verificando = false;
    }
  }

  Future<void> _abrirCalificacion(Viaje v) async {
    if (_calificacionAbierta) return;
    _calificacionAbierta = true;
    // Espera a que termine el frame para no abrir la hoja durante el build.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await mostrarCalificar(context, v);
  }

  @override
  void initState() {
    super.initState();
    // listenManual (no ref.listen en build) para poder llamar setState sin riesgo.
    ref.listenManual<AsyncValue<Viaje?>>(viajeActivoClienteProvider, (_, next) {
      if (next.isLoading || next.hasError) return;
      final v = next.value;
      if (v != null && v.id == widget.viajeId && !v.estado.terminado) {
        if (mounted && !identical(v, _viaje)) setState(() => _viaje = v);
        return;
      }
      _verificarFin();
    });
    // Estado inicial (p. ej. si se abre el seguimiento de un viaje que ya terminó).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final actual = ref.read(viajeActivoClienteProvider);
      final v = actual.value;
      if (v != null && v.id == widget.viajeId) {
        setState(() => _viaje = v);
      } else if (actual.hasValue) {
        _verificarFin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mantiene vivo el polling del viaje activo mientras la pantalla está abierta.
    ref.watch(viajeActivoClienteProvider);

    final terminado = _terminado;
    final v = terminado ?? _viaje;
    final punto = terminado == null ? ref.watch(seguimientoViajeProvider(widget.viajeId)) : null;
    final pos = punto?.value?.posicion;
    final conductor = pos == null ? null : LatLng(pos.lat, pos.lng);
    final objetivo = v == null
        ? null
        : (v.estado == EstadoViaje.enCurso ? v.destino : v.origen);

    return GavPage(
      children: [
        GavTopBar(
          eyebrow: 'GAV · Cliente',
          title: 'Seguimiento',
          subtitle: v?.ruta ?? 'Viaje #${widget.viajeId}',
          onBack: () => context.canPop() ? context.pop() : context.go('/cliente'),
        ),
        if (v != null)
          GavCard(
            child: Row(
              children: [
                GavAvatar(v.conductorNombre ?? '?', size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.conductorNombre ?? 'Conductor', style: GavText.strong(context, size: 14.5)),
                      const SizedBox(height: 2),
                      Text(Fmt.pesos(v.precio), style: GavText.muted(context, size: 12)),
                    ],
                  ),
                ),
                EstadoViajeChip(v.estado),
              ],
            ),
          ),
        GavMapa(
          height: 260,
          origen: v == null ? null : LatLng(v.origen.lat, v.origen.lng),
          destino: v == null ? null : LatLng(v.destino.lat, v.destino.lng),
          conductor: conductor,
          // Tramo real conductor → punto de recogida (o → destino si ya va en curso).
          tramoConductorHasta: terminado == null && objetivo != null ? LatLng(objetivo.lat, objetivo.lng) : null,
          onTramoConductor: (r) {
            if (mounted) setState(() => _tramo = r);
          },
        ),
        const SizedBox(height: 10),
        if (terminado != null)
          _ViajeTerminadoCard(viaje: terminado, onCalificar: () => mostrarCalificar(context, terminado))
        else
          AsyncValueView<PuntoSeguimiento?>(
            value: punto!,
            onRetry: () => ref.invalidate(seguimientoViajeProvider(widget.viajeId)),
            isEmpty: (p) => p == null,
            empty: const GavCard(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: EmptyView(
                mensaje: 'Esperando la primera ubicación del conductor…',
                icono: Icons.gps_not_fixed,
              ),
            ),
            data: (p) => _PosicionCard(punto: p!, viaje: v, tramo: _tramo),
          ),
      ],
    );
  }
}

class _ViajeTerminadoCard extends StatelessWidget {
  const _ViajeTerminadoCard({required this.viaje, required this.onCalificar});
  final Viaje viaje;
  final VoidCallback onCalificar;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final finalizado = viaje.estado == EstadoViaje.finalizado;
    return GavCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GavIconBox(
            icon: finalizado ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: finalizado ? g.success : g.danger,
            background: finalizado ? g.successContainer : g.dangerContainer,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(finalizado ? '¡Llegaste a tu destino!' : 'El viaje fue cancelado',
              style: GavText.strong(context, size: 17)),
          const SizedBox(height: 4),
          Text(
            finalizado
                ? '${viaje.ruta}\nTotal: ${Fmt.pesos(viaje.precio)}'
                : 'Puedes solicitar un nuevo viaje cuando quieras.',
            textAlign: TextAlign.center,
            style: GavText.muted(context, size: 12.5),
          ),
          const SizedBox(height: 16),
          if (finalizado && viaje.tieneConductor) ...[
            GavButton(
              label: 'Calificar a ${viaje.conductorNombre}',
              kind: GavButtonKind.gold,
              expand: true,
              onPressed: onCalificar,
            ),
            const SizedBox(height: 10),
          ],
          GavButton(
            label: 'Volver al inicio',
            expand: true,
            onPressed: () => context.go('/cliente'),
          ),
        ],
      ),
    );
  }
}

class _PosicionCard extends StatelessWidget {
  const _PosicionCard({required this.punto, this.viaje, this.tramo});
  final PuntoSeguimiento punto;
  final Viaje? viaje;

  /// Distancia/tiempo por calles del tramo conductor → objetivo (null si no hay Directions).
  final RutaCalculada? tramo;

  @override
  Widget build(BuildContext context) {
    final pos = punto.posicion;
    final cerca = Lugares.cercano(pos.lat, pos.lng);
    final v = viaje;
    final enCurso = v?.estado == EstadoViaje.enCurso;
    // Mientras va en camino, la referencia es el origen; durante el viaje, el destino.
    final objetivo = v == null ? null : (enCurso ? v.destino : v.origen);
    final kmRecta = objetivo == null ? null : Lugares.distanciaKm(pos.lat, pos.lng, objetivo.lat, objetivo.lng);
    final km = tramo?.km ?? kmRecta;
    final minutos = tramo?.minutos ?? (kmRecta == null ? null : (kmRecta * 1.35 / 24 * 60).ceil());

    return GavCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: context.gav.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text('EN VIVO', style: GavText.label(context).copyWith(color: context.gav.success)),
              const Spacer(),
              Text('Actualizado ${Fmt.hora(punto.fecha)}', style: GavText.muted(context, size: 11)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            cerca != null ? 'Cerca de ${cerca.nombre}' : (enCurso ? 'Viaje en curso' : 'Conductor en ruta'),
            style: GavText.strong(context, size: 16),
          ),
          const SizedBox(height: 4),
          Text(pos.toString(), style: GavText.muted(context, size: 12)),
          if (km != null && minutos != null) ...[
            const SizedBox(height: 14),
            GavKpiGrid(
              children: [
                GavKpiCard(
                  label: enCurso ? 'Distancia al destino' : 'Distancia a tu punto',
                  value: '${km.toStringAsFixed(1).replaceAll('.', ',')} km',
                ),
                GavKpiCard(label: 'Llegada aprox.', value: '$minutos min'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
