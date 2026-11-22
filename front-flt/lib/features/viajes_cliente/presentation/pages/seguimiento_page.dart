import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:material_ui/material_ui.dart';

import '../../../../core/lugares/lugares.dart';
import '../../../../core/lugares/ruta_viaje.dart';
import '../../../../core/maps/gav_mapa.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/viaje.dart';
import '../controllers/viajes_cliente_providers.dart';
import '../widgets/viaje_widgets.dart';

/// Cliente · Seguimiento en vivo (posición del conductor cada 6 s).
class SeguimientoPage extends ConsumerWidget {
  const SeguimientoPage({super.key, required this.viajeId});
  final int viajeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final punto = ref.watch(seguimientoViajeProvider(viajeId));
    final viaje = ref.watch(viajeActivoClienteProvider).value;
    final v = viaje?.id == viajeId ? viaje : null;

    return GavPage(
      children: [
        GavTopBar(
          eyebrow: 'GAV · Cliente',
          title: 'Seguimiento',
          subtitle: v?.ruta ?? 'Viaje #$viajeId',
          onBack: () => context.pop(),
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
          conductor: punto.value == null
              ? null
              : LatLng(punto.value!.posicion.lat, punto.value!.posicion.lng),
        ),
        const SizedBox(height: 10),
        AsyncValueView<PuntoSeguimiento?>(
          value: punto,
          onRetry: () => ref.invalidate(seguimientoViajeProvider(viajeId)),
          isEmpty: (p) => p == null,
          empty: const GavCard(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: EmptyView(
              mensaje: 'Esperando la primera ubicación del conductor…',
              icono: Icons.gps_not_fixed,
            ),
          ),
          data: (p) => _PosicionCard(punto: p!, viaje: v),
        ),
      ],
    );
  }
}

class _PosicionCard extends StatelessWidget {
  const _PosicionCard({required this.punto, this.viaje});
  final PuntoSeguimiento punto;
  final Viaje? viaje;

  @override
  Widget build(BuildContext context) {
    final pos = punto.posicion;
    final cerca = Lugares.cercano(pos.lat, pos.lng);
    final v = viaje;
    // Mientras va en camino, la referencia es el origen; durante el viaje, el destino.
    final objetivo = v == null ? null : (v.estado.name == 'enCurso' ? v.destino : v.origen);
    final km = objetivo == null ? null : Lugares.distanciaKm(pos.lat, pos.lng, objetivo.lat, objetivo.lng);

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
            cerca != null ? 'Cerca de ${cerca.nombre}' : 'Conductor en ruta',
            style: GavText.strong(context, size: 16),
          ),
          const SizedBox(height: 4),
          Text(pos.toString(), style: GavText.muted(context, size: 12)),
          if (km != null) ...[
            const SizedBox(height: 14),
            GavKpiGrid(
              children: [
                GavKpiCard(
                  label: v!.estado.name == 'enCurso' ? 'Distancia al destino' : 'Distancia a tu punto',
                  value: '${km.toStringAsFixed(1).replaceAll('.', ',')} km',
                ),
                GavKpiCard(label: 'Llegada aprox.', value: '${(km * 1.35 / 24 * 60).ceil()} min'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
