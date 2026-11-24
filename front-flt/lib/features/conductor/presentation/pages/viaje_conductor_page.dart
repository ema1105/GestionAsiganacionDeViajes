import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:material_ui/material_ui.dart';

import '../../../../core/lugares/lugares.dart';
import '../../../../core/maps/gav_mapa.dart';
import '../../../../core/maps/ruta_calculada.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../viajes_cliente/domain/entities/estado_viaje.dart';
import '../../../viajes_cliente/domain/entities/viaje.dart';
import '../../../viajes_cliente/presentation/widgets/viaje_widgets.dart';
import '../../data/conductor_repository_impl.dart';
import '../../domain/conductor_models.dart';
import '../../domain/solicitud_pendiente.dart';
import '../controllers/conductor_providers.dart';
import '../controllers/rastreo_conductor.dart';
import '../widgets/acciones_viaje.dart';

/// Contacto del cliente del viaje activo (teléfono / email).
final _contactoClienteProvider = FutureProvider.autoDispose.family<ContactoCliente, int>(
  (ref, viajeId) => ref.watch(conductorRepositoryProvider).contactoCliente(viajeId),
);

/// Conductor · Viaje: toda la información del viaje activo y sus acciones
/// (Voy en camino → Iniciar viaje → Finalizar viaje).
class ViajeConductorPage extends ConsumerWidget {
  const ViajeConductorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activo = ref.watch(viajeActivoConductorProvider);
    return GavPage(
      onRefresh: () async {
        ref.invalidate(viajeActivoConductorProvider);
        await ref.read(viajeActivoConductorProvider.future);
      },
      children: [
        const GavTopBar(
          eyebrow: 'GAV · Conductor',
          title: 'Viaje',
          subtitle: 'Detalle completo de tu viaje activo',
        ),
        AsyncValueView<Viaje?>(
          value: activo,
          onRetry: () => ref.invalidate(viajeActivoConductorProvider),
          isEmpty: (v) => v == null,
          empty: const GavCard(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: EmptyView(
              mensaje: 'No tienes un viaje activo. Cuando aceptes una solicitud verás aquí todo el detalle.',
              icono: Icons.route_outlined,
            ),
          ),
          data: (v) => _DetalleViaje(viaje: v!),
        ),
      ],
    );
  }
}

class _DetalleViaje extends ConsumerStatefulWidget {
  const _DetalleViaje({required this.viaje});
  final Viaje viaje;

  @override
  ConsumerState<_DetalleViaje> createState() => _DetalleViajeState();
}

class _DetalleViajeState extends ConsumerState<_DetalleViaje> {
  RutaCalculada? _ruta;
  RutaCalculada? _tramo;
  bool _enviando = false;

  Future<void> _ejecutar(AccionConductor accion) async {
    setState(() => _enviando = true);
    await ejecutarAccionConductor(context, ref, accion, widget.viaje);
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final v = widget.viaje;
    final accion = AccionConductor.siguiente(v.estado);
    final enCurso = v.estado == EstadoViaje.enCurso;
    final r = ref.watch(rastreoConductorProvider);
    final yo = r.lat == null || r.lng == null ? null : LatLng(r.lat!, r.lng!);

    // Distancia/tiempo del viaje: Directions si está disponible; si no, estimación.
    final kmRecta = Lugares.distanciaKm(v.origen.lat, v.origen.lng, v.destino.lat, v.destino.lng);
    final km = _ruta?.km ?? kmRecta * 1.35;
    final minutos = _ruta?.minutos ?? (kmRecta * 1.35 / 24 * 60).ceil();
    final contacto = ref.watch(_contactoClienteProvider(v.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Cliente ──
        GavCard(
          child: Row(
            children: [
              GavAvatar(v.clienteNombre ?? '?', size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CLIENTE', style: GavText.label(context)),
                    const SizedBox(height: 2),
                    Text(
                      contacto.value?.nombre.isNotEmpty == true ? contacto.value!.nombre : (v.clienteNombre ?? 'Cliente'),
                      style: GavText.strong(context, size: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${v.cantidadPasajeros} pasajero${v.cantidadPasajeros == 1 ? '' : 's'}'
                      '${contacto.value?.telefono != null ? ' · Tel. ${contacto.value!.telefono}' : ''}',
                      style: GavText.muted(context, size: 12),
                    ),
                  ],
                ),
              ),
              if (contacto.value?.telefono != null)
                GavIconButton(
                  icon: Icons.copy_outlined,
                  tooltip: 'Copiar teléfono',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: contacto.value!.telefono!));
                    showInfoSnack(context, 'Teléfono copiado');
                  },
                ),
              const SizedBox(width: 6),
              EstadoViajeChip(v.estado),
            ],
          ),
        ),

        // ── Mapa con la ruta real ──
        GavMapa(
          height: 300,
          origen: LatLng(v.origen.lat, v.origen.lng),
          destino: LatLng(v.destino.lat, v.destino.lng),
          conductor: yo,
          // Antes de iniciar: también se traza mi posición → punto de recogida.
          tramoConductorHasta: enCurso ? null : LatLng(v.origen.lat, v.origen.lng),
          onRuta: (x) {
            if (mounted) setState(() => _ruta = x);
          },
          onTramoConductor: (x) {
            if (mounted) setState(() => _tramo = x);
          },
        ),
        const SizedBox(height: 12),

        // ── Valor, distancia, tiempo ──
        GavKpiGrid(
          children: [
            GavKpiCard(label: 'Valor del viaje', value: Fmt.pesos(v.precio)),
            GavKpiCard(
              label: _ruta != null ? 'Distancia (por calles)' : 'Distancia estimada',
              value: '${km.toStringAsFixed(1).replaceAll('.', ',')} km',
            ),
            GavKpiCard(label: 'Tiempo estimado', value: '$minutos min'),
            if (!enCurso && _tramo != null)
              GavKpiCard(
                label: 'Hasta el cliente',
                value: '${_tramo!.km.toStringAsFixed(1).replaceAll('.', ',')} km · ${_tramo!.minutos} min',
              ),
          ],
        ),

        // ── Recorrido ──
        GavCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Punto(
                icono: Icons.trip_origin,
                color: g.gold,
                etiqueta: 'RECOGIDA',
                texto: v.origenNombre ?? v.origen.toString(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: Container(width: 2, height: 18, color: g.border),
              ),
              _Punto(
                icono: Icons.place,
                color: g.success,
                etiqueta: 'DESTINO',
                texto: v.destinoNombre ?? v.destino.toString(),
              ),
              const SizedBox(height: 10),
              Text(
                'Solicitado ${Fmt.fechaCorta(v.solicitadoEn)}'
                '${v.iniciadoEn != null ? ' · Iniciado ${Fmt.hora(v.iniciadoEn)}' : ''}',
                style: GavText.muted(context, size: 12),
              ),
            ],
          ),
        ),

        // ── Acción ──
        if (accion != null)
          GavButton(
            label: _enviando ? 'Enviando…' : accion.etiqueta.toUpperCase(),
            kind: GavButtonKind.gold,
            icon: switch (accion) {
              AccionConductor.enCamino => Icons.navigation_outlined,
              AccionConductor.iniciar => Icons.play_arrow_rounded,
              AccionConductor.finalizar => Icons.flag_outlined,
            },
            expand: true,
            height: 52,
            onPressed: _enviando ? null : () => _ejecutar(accion),
          ),
        const SizedBox(height: 8),
        Text(
          switch (v.estado) {
            EstadoViaje.aceptado => 'Toca "Voy en camino" cuando salgas hacia el punto de recogida.',
            EstadoViaje.enCamino => 'Al recoger al cliente toca "Iniciar viaje".',
            EstadoViaje.enCurso => 'Al llegar al destino toca "Finalizar viaje" y califica al cliente.',
            _ => '',
          },
          textAlign: TextAlign.center,
          style: GavText.muted(context, size: 11.5),
        ),
      ],
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.icono, required this.color, required this.etiqueta, required this.texto});
  final IconData icono;
  final Color color;
  final String etiqueta;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: GavText.label(context)),
                Text(texto, style: GavText.strong(context, size: 13.5)),
              ],
            ),
          ),
        ],
      );
}
