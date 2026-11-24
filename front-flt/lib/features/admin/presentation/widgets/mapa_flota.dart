import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/maps/gav_mapa.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../data/admin_repository.dart';

/// Matiz del marcador dorado (≈ #A98845) y del verde de "disponible".
const _hueEnViaje = 40.0;

/// Mapa de la flota en vivo: un marcador por conductor conectado
/// (verde = disponible, dorado = en viaje) y, para los que van en viaje,
/// la ruta por calles hasta su punto de recogida o su destino.
class MapaFlota extends StatefulWidget {
  const MapaFlota({
    super.key,
    required this.conductores,
    required this.onSeleccionar,
    this.seleccionadoId,
    this.height = 520,
  });

  final List<ConductorEnVivo> conductores;
  final int? seleccionadoId;
  final ValueChanged<int> onSeleccionar;
  final double height;

  @override
  State<MapaFlota> createState() => _MapaFlotaState();
}

class _MapaFlotaState extends State<MapaFlota> {
  static const _cartagena = LatLng(10.4236, -75.5300);

  GoogleMapController? _controller;
  bool _encuadrado = false;

  /// Ruta por calles de cada conductor en viaje (id → puntos).
  final Map<int, List<LatLng>> _rutas = {};

  @override
  void initState() {
    super.initState();
    _calcularRutas();
  }

  @override
  void didUpdateWidget(covariant MapaFlota oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.conductores, widget.conductores)) _calcularRutas();
    if (oldWidget.seleccionadoId != widget.seleccionadoId && widget.seleccionadoId != null) {
      unawaited(_centrarEn(widget.seleccionadoId!));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _calcularRutas() async {
    final enViaje = widget.conductores.where((c) => c.objetivo != null).toList();
    _rutas.removeWhere((id, _) => !enViaje.any((c) => c.id == id));
    for (final c in enViaje) {
      final o = c.objetivo!;
      final r = await rutaPorCallesCacheada(LatLng(c.lat, c.lng), LatLng(o.lat, o.lng), decimales: 3);
      if (!mounted) return;
      if (r != null && r.puntos.length >= 2) setState(() => _rutas[c.id] = r.puntos);
    }
    if (!_encuadrado && widget.conductores.isNotEmpty) {
      _encuadrado = true;
      unawaited(encuadrarFlota());
    }
  }

  /// Muestra a todos los conductores conectados.
  Future<void> encuadrarFlota() async {
    final c = _controller;
    final pts = widget.conductores.map((x) => LatLng(x.lat, x.lng)).toList();
    if (c == null || pts.isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      if (pts.length == 1) {
        await c.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 14));
        return;
      }
      var sw = pts.first, ne = pts.first;
      for (final p in pts) {
        sw = LatLng(p.latitude < sw.latitude ? p.latitude : sw.latitude,
            p.longitude < sw.longitude ? p.longitude : sw.longitude);
        ne = LatLng(p.latitude > ne.latitude ? p.latitude : ne.latitude,
            p.longitude > ne.longitude ? p.longitude : ne.longitude);
      }
      await c.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 70));
    } catch (_) {
      // El mapa aún no tiene tamaño; el próximo cambio lo reencuadra.
    }
  }

  Future<void> _centrarEn(int id) async {
    final c = _controller;
    ConductorEnVivo? x;
    for (final e in widget.conductores) {
      if (e.id == id) x = e;
    }
    if (c == null || x == null) return;
    try {
      await c.animateCamera(CameraUpdate.newLatLngZoom(LatLng(x.lat, x.lng), 15));
      await c.showMarkerInfoWindow(MarkerId('c$id'));
    } catch (_) {}
  }

  static String _hace(ConductorEnVivo c) {
    final s = c.segundosSinSenal;
    return s == null ? '' : ' · hace $s s';
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: g.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: g.border),
      ),
      child: FutureBuilder<bool>(
        future: mapsListos,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snap.data != true) {
            return Center(
              child: Text('Mapa no disponible. Revisa MAPS_API_KEY en env/*.json.',
                  style: GavText.muted(context, size: 12)),
            );
          }

          final markers = <Marker>{
            for (final c in widget.conductores)
              Marker(
                markerId: MarkerId('c${c.id}'),
                position: LatLng(c.lat, c.lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    c.enViaje ? _hueEnViaje : BitmapDescriptor.hueGreen),
                infoWindow: InfoWindow(
                  title: '${c.nombre}${c.placa != null ? ' · ${c.placa}' : ''}',
                  snippet: c.enViaje
                      ? 'En viaje #${c.viajeId}${_hace(c)}'
                      : 'Disponible${_hace(c)}',
                ),
                onTap: () => widget.onSeleccionar(c.id),
              ),
          };

          final polylines = <Polyline>{};
          for (final c in widget.conductores.where((x) => x.objetivo != null)) {
            final o = c.objetivo!;
            final puntos = _rutas[c.id] ?? [LatLng(c.lat, c.lng), LatLng(o.lat, o.lng)];
            final real = _rutas.containsKey(c.id);
            polylines.add(Polyline(
              polylineId: PolylineId('r${c.id}'),
              points: puntos,
              color: g.gold,
              width: real ? 4 : 3,
              patterns: [PatternItem.dash(14), PatternItem.gap(10)],
            ));
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(target: _cartagena, zoom: 12),
                style: oscuro ? estiloMapaOscuro : null,
                markers: markers,
                polylines: polylines,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (c) {
                  _controller = c;
                  if (widget.conductores.isNotEmpty) {
                    _encuadrado = true;
                    unawaited(encuadrarFlota());
                  }
                },
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: g.background.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Punto(color: g.success),
                      const SizedBox(width: 6),
                      Text('Disponible', style: GavText.muted(context, size: 11.5)),
                      const SizedBox(width: 14),
                      _Punto(color: g.gold),
                      const SizedBox(width: 6),
                      Text('En viaje (con ruta)', style: GavText.muted(context, size: 11.5)),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Material(
                  color: g.primaryButton,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Centrar la flota',
                    icon: Icon(Icons.center_focus_strong, color: g.onPrimaryButton),
                    onPressed: encuadrarFlota,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
