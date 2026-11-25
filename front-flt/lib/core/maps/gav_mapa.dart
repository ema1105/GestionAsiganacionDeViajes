import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../config/env.dart';
import '../theme/gav_colors.dart';
import '../theme/gav_theme.dart';
import 'maps_plataforma.dart';
import 'ruta_calculada.dart';

/// Caché de rutas por calles (clave = coordenadas redondeadas) para no repetir
/// llamadas a Directions cada vez que el polling reconstruye el mapa.
final Map<String, RutaCalculada> _cacheRutas = {};

String _claveRuta(LatLng a, LatLng b, {int decimales = 5}) =>
    '${a.latitude.toStringAsFixed(decimales)},${a.longitude.toStringAsFixed(decimales)}'
    '>${b.latitude.toStringAsFixed(decimales)},${b.longitude.toStringAsFixed(decimales)}';

/// Ruta por calles a → b con caché. [decimales] redondea la clave (3 ≈ 100 m) para
/// no recalcular por pequeños movimientos del GPS. null si ninguna API de rutas responde.
Future<RutaCalculada?> rutaPorCallesCacheada(LatLng a, LatLng b, {int decimales = 5}) async {
  final k = _claveRuta(a, b, decimales: decimales);
  final cache = _cacheRutas[k];
  if (cache != null) return cache;
  if (!await mapsListos) return null;
  final r = await calcularRutaPorCalles(a.latitude, a.longitude, b.latitude, b.longitude);
  if (r != null) _cacheRutas[k] = r; // los fallos no se guardan: se reintenta luego
  return r;
}

/// Carga única de Google Maps para toda la app.
final Future<bool> mapsListos = cargarGoogleMaps(Env.tieneMapa ? Env.mapsApiKey : '');

/// Mapa de GAV: origen (dorado), destino (verde) y conductor (azul) + ruta.
/// Si no hay clave o la plataforma no tiene mapas, muestra un aviso en su lugar.
class GavMapa extends StatefulWidget {
  const GavMapa({
    super.key,
    this.origen,
    this.destino,
    this.conductor,
    this.ruta,
    this.height = 220,
    this.onTap,
    this.rutaAutomatica = true,
    this.tramoConductorHasta,
    this.onTramoConductor,
    this.onRuta,
  });

  final LatLng? origen;
  final LatLng? destino;
  final LatLng? conductor;

  /// Trazado por calles ya calculado. Si es null y [rutaAutomatica] es true, el mapa
  /// calcula la ruta real origen → destino (Directions/Routes); si no hay ruta
  /// disponible, dibuja una línea recta punteada.
  final List<LatLng>? ruta;
  final bool rutaAutomatica;

  /// Si se indica junto con [conductor], se traza también la ruta por calles
  /// conductor → este punto (p. ej. conductor → punto de recogida).
  final LatLng? tramoConductorHasta;

  /// Distancia/tiempo reales del tramo conductor → [tramoConductorHasta].
  final ValueChanged<RutaCalculada?>? onTramoConductor;

  /// Distancia/tiempo reales de la ruta origen → destino calculada automáticamente.
  final ValueChanged<RutaCalculada?>? onRuta;
  final double height;

  /// Si se indica, el usuario puede tocar el mapa para elegir un punto (p. ej. el destino).
  final ValueChanged<LatLng>? onTap;

  @override
  State<GavMapa> createState() => _GavMapaState();
}

class _GavMapaState extends State<GavMapa> {
  GoogleMapController? _controller;
  List<LatLng>? _rutaAuto;
  List<LatLng>? _rutaTramo;

  static const _cartagena = LatLng(10.4236, -75.5300);

  @override
  void initState() {
    super.initState();
    _calcularRuta();
    _calcularTramo();
  }

  Future<void> _calcularRuta() async {
    final o = widget.origen, d = widget.destino;
    if (widget.ruta != null || !widget.rutaAutomatica || o == null || d == null) {
      if (_rutaAuto != null && mounted) setState(() => _rutaAuto = null);
      return;
    }
    final r = await rutaPorCallesCacheada(o, d);
    if (!mounted || widget.origen != o || widget.destino != d) return;
    setState(() => _rutaAuto = r?.puntos);
    widget.onRuta?.call(r);
  }

  /// Tramo conductor → objetivo. Se redondea a 3 decimales (~100 m) para no
  /// recalcular con cada pequeño movimiento del GPS.
  Future<void> _calcularTramo() async {
    final c = widget.conductor, h = widget.tramoConductorHasta;
    if (c == null || h == null) {
      if (_rutaTramo != null && mounted) setState(() => _rutaTramo = null);
      return;
    }
    final r = await rutaPorCallesCacheada(c, h, decimales: 3);
    if (!mounted || widget.conductor != c || widget.tramoConductorHasta != h) return;
    setState(() => _rutaTramo = r?.puntos);
    widget.onTramoConductor?.call(r);
  }

  List<LatLng> get _puntos => [
        ?widget.origen,
        ?widget.destino,
        ?widget.conductor,
      ];

  @override
  void didUpdateWidget(covariant GavMapa oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cambio = oldWidget.origen != widget.origen ||
        oldWidget.destino != widget.destino ||
        oldWidget.conductor != widget.conductor;
    if (cambio) _encuadrar();
    if (oldWidget.origen != widget.origen || oldWidget.destino != widget.destino || oldWidget.ruta != widget.ruta) {
      _calcularRuta();
    }
    if (oldWidget.conductor != widget.conductor || oldWidget.tramoConductorHasta != widget.tramoConductorHasta) {
      _calcularTramo();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _encuadrar() async {
    final c = _controller;
    final pts = _puntos;
    if (c == null || pts.isEmpty) return;
    // En web el mapa necesita un instante para medir su tamaño.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      if (pts.length == 1) {
        await c.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 15));
        return;
      }
      var sw = pts.first, ne = pts.first;
      for (final p in pts) {
        sw = LatLng(p.latitude < sw.latitude ? p.latitude : sw.latitude,
            p.longitude < sw.longitude ? p.longitude : sw.longitude);
        ne = LatLng(p.latitude > ne.latitude ? p.latitude : ne.latitude,
            p.longitude > ne.longitude ? p.longitude : ne.longitude);
      }
      await c.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 60));
    } catch (_) {
      // Si el mapa aún no tiene tamaño, se ignora; el siguiente cambio lo reencuadra.
    }
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: g.border),
      ),
      child: FutureBuilder<bool>(
        future: mapsListos,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snap.data != true) return _SinMapa(height: widget.height);

          final o = widget.origen, d = widget.destino, cond = widget.conductor;
          final markers = <Marker>{
            if (o != null)
              Marker(
                markerId: const MarkerId('origen'),
                position: o,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                infoWindow: const InfoWindow(title: 'Origen'),
              ),
            if (d != null)
              Marker(
                markerId: const MarkerId('destino'),
                position: d,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: 'Destino'),
              ),
            if (cond != null)
              Marker(
                markerId: const MarkerId('conductor'),
                position: cond,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: const InfoWindow(title: 'Conductor'),
              ),
          };
          final real = widget.ruta ?? _rutaAuto;
          final trazado = real ?? (o != null && d != null ? [o, d] : const <LatLng>[]);
          final tramo = _rutaTramo;

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: _puntos.isEmpty ? _cartagena : _puntos.first, zoom: 13),
            style: oscuro ? estiloMapaOscuro : null,
            markers: markers,
            polylines: {
              if (trazado.length >= 2)
                Polyline(
                  polylineId: const PolylineId('ruta'),
                  points: trazado,
                  color: g.gold,
                  width: real == null ? 3 : 5,
                  patterns: real == null ? [PatternItem.dash(14), PatternItem.gap(10)] : const [],
                ),
              if (tramo != null && tramo.length >= 2)
                Polyline(
                  polylineId: const PolylineId('tramo_conductor'),
                  points: tramo,
                  color: const Color(0xFF4FA3E0),
                  width: 4,
                ),
            },
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            onTap: widget.onTap,
            onMapCreated: (c) {
              _controller = c;
              unawaited(_encuadrar());
            },
          );
        },
      ),
    );
  }
}

class _SinMapa extends StatelessWidget {
  const _SinMapa({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, color: context.gav.textFaint),
              const SizedBox(height: 8),
              Text(
                Env.tieneMapa
                    ? 'Mapa no disponible en esta plataforma.'
                    : 'Configura MAPS_API_KEY en env/*.json para ver el mapa.',
                textAlign: TextAlign.center,
                style: GavText.muted(context, size: 12),
              ),
            ],
          ),
        ),
      );
}

/// Estilo oscuro acorde al tema GAV (también lo usa el mapa "Flota en vivo").
const estiloMapaOscuro = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1c1c1b"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9c9891"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0a0a"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2b29"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3a3527"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1a22"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#181817"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]
''';
