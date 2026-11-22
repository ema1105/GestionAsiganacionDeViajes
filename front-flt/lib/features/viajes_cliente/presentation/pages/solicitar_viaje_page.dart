import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:material_ui/material_ui.dart';

import '../../../../core/config/env.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/location/ubicacion.dart';
import '../../../../core/lugares/lugares.dart';
import '../../../../core/maps/gav_mapa.dart';
import '../../../../core/maps/maps_plataforma.dart';
import '../../../../core/maps/ruta_calculada.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../data/cliente_repository.dart';
import '../controllers/viajes_cliente_providers.dart';

/// Cliente · Solicitar viaje.
/// Origen: catálogo o ubicación actual. Destino: catálogo, búsqueda de Google o toque en el mapa.
class SolicitarViajePage extends ConsumerStatefulWidget {
  const SolicitarViajePage({super.key, this.destinoInicial});

  /// Nombre de un lugar popular tocado en Inicio.
  final String? destinoInicial;

  @override
  ConsumerState<SolicitarViajePage> createState() => _SolicitarViajePageState();
}

class _SolicitarViajePageState extends ConsumerState<SolicitarViajePage> {
  Lugar? _origen;
  Lugar? _destino;
  int _pasajeros = 1;
  bool _enviando = false;
  bool _ubicando = false;
  String? _error;
  RutaCalculada? _rutaCalles;

  @override
  void initState() {
    super.initState();
    final d = widget.destinoInicial;
    if (d != null) {
      for (final l in Lugares.todos) {
        if (l.nombre == d) _destino = l;
      }
    }
  }

  Future<void> _elegir({required bool origen}) async {
    final l = await showModalBottomSheet<Lugar>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SelectorLugar(
        titulo: origen ? '¿Dónde te recogemos?' : '¿A dónde vas?',
        buscarEnGoogle: !origen && Env.tieneMapa,
      ),
    );
    if (l == null) return;
    setState(() {
      if (origen) {
        _origen = l;
      } else {
        _destino = l;
      }
      _error = null;
    });
    await _recalcular();
  }

  /// Ruta por calles con Directions (web). Si no está disponible, se usa la estimación.
  Future<void> _recalcular() async {
    final o = _origen, d = _destino;
    setState(() => _rutaCalles = null);
    if (o == null || d == null || _mismoPunto(o, d)) return;
    await mapsListos;
    final r = await calcularRutaPorCalles(o.lat, o.lng, d.lat, d.lng);
    final oAhora = _origen, dAhora = _destino;
    if (mounted && oAhora != null && dAhora != null && _mismoPunto(o, oAhora) && _mismoPunto(d, dAhora)) {
      setState(() => _rutaCalles = r);
    }
  }

  static bool _mismoPunto(Lugar a, Lugar b) =>
      (a.lat - b.lat).abs() < 1e-6 && (a.lng - b.lng).abs() < 1e-6;

  /// Destino = punto tocado en el mapa. Si cae en un lugar del catálogo se usa ese lugar;
  /// si no, se muestra "Punto en el mapa" y se reemplaza por la dirección (Geocoding API).
  Future<void> _elegirEnMapa(LatLng p) async {
    final catalogo = Lugares.cercano(p.latitude, p.longitude);
    final provisional =
        catalogo ?? Lugar('Punto en el mapa', 'Punto en el mapa', 'OTRO', p.latitude, p.longitude);
    setState(() {
      _destino = provisional;
      _error = null;
    });
    unawaited(_recalcular());
    if (catalogo != null) return;

    final direccion = await direccionDe(p.latitude, p.longitude);
    if (!mounted || direccion == null || !identical(_destino, provisional)) return;
    final nombre = acortarDireccion(direccion);
    setState(() => _destino = Lugar(nombre, nombre, 'OTRO', p.latitude, p.longitude));
  }

  /// Origen = posición GPS actual del cliente (pide permiso de ubicación).
  Future<void> _usarMiUbicacion() async {
    setState(() {
      _ubicando = true;
      _error = null;
    });
    final permiso = await Ubicacion.solicitarPermiso();
    final pos = permiso.ok ? await Ubicacion.actual() : null;
    if (!mounted) return;
    if (pos == null) {
      setState(() {
        _ubicando = false;
        _error = permiso.ok ? EstadoPermiso.noDisponible.mensaje : permiso.mensaje;
      });
      return;
    }
    final cerca = Lugares.cercano(pos.latitude, pos.longitude);
    setState(() {
      _ubicando = false;
      _origen = Lugar(
        cerca != null ? 'Mi ubicación (cerca de ${cerca.corto})' : 'Mi ubicación',
        'Mi ubicación',
        'OTRO',
        pos.latitude,
        pos.longitude,
      );
    });
    await _recalcular();
  }

  Future<void> _solicitar() async {
    final o = _origen;
    final d = _destino;
    if (o == null || d == null) {
      setState(() => _error = 'Elige el origen y el destino.');
      return;
    }
    if (_mismoPunto(o, d)) {
      setState(() => _error = 'El origen y el destino deben ser distintos.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final estimada = Lugares.estimarRuta(o, d);
      final viaje = await ref.read(clienteRepositoryProvider).solicitar(
            origen: o,
            destino: d,
            pasajeros: _pasajeros,
            km: _rutaCalles?.km ?? estimada.km,
            minutos: _rutaCalles?.minutos ?? estimada.minutos,
          );
      ref.invalidate(viajeActivoClienteProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Viaje #${viaje.id} solicitado · ${Fmt.pesos(viaje.precio)}. Buscando conductor…')),
      );
      context.pop();
    } catch (e) {
      setState(() => _error = userMessageOf(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final o = _origen;
    final d = _destino;
    final estimada = (o != null && d != null && !_mismoPunto(o, d)) ? Lugares.estimarRuta(o, d) : null;
    final km = _rutaCalles?.km ?? estimada?.km;
    final minutos = _rutaCalles?.minutos ?? estimada?.minutos;

    return GavPage(
      children: [
        GavTopBar(
          eyebrow: 'GAV · Cliente',
          title: 'Solicitar viaje',
          subtitle: 'Elige tu origen, destino y pasajeros',
          onBack: () => context.pop(),
        ),
        GavMapa(
          height: (MediaQuery.sizeOf(context).height * 0.45).clamp(300.0, 480.0),
          origen: o == null ? null : LatLng(o.lat, o.lng),
          destino: d == null ? null : LatLng(d.lat, d.lng),
          ruta: _rutaCalles?.puntos,
          onTap: _elegirEnMapa,
        ),
        if (Env.tieneMapa)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 14, color: g.textFaint),
                const SizedBox(width: 6),
                Text('Toca el mapa para elegir tu destino', style: GavText.muted(context, size: 11.5)),
              ],
            ),
          ),
        const SizedBox(height: 10),
        GavCard(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          child: Column(
            children: [
              _FilaLugar(
                etiqueta: 'ORIGEN',
                lugar: o,
                icono: Icons.trip_origin,
                color: g.gold,
                onTap: () => _elegir(origen: true),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _ubicando ? null : _usarMiUbicacion,
                  style: TextButton.styleFrom(foregroundColor: g.gold, padding: EdgeInsets.zero),
                  icon: _ubicando
                      ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 16),
                  label: Text(_ubicando ? 'Obteniendo ubicación…' : 'Usar mi ubicación actual'),
                ),
              ),
              Divider(color: g.border),
              _FilaLugar(
                etiqueta: 'DESTINO',
                lugar: d,
                icono: Icons.place,
                color: g.success,
                onTap: () => _elegir(origen: false),
              ),
            ],
          ),
        ),
        GavCard(
          child: Row(
            children: [
              Expanded(child: Text('Pasajeros', style: GavText.strong(context, size: 14))),
              GavIconButton(
                icon: Icons.remove,
                onTap: _pasajeros > 1 ? () => setState(() => _pasajeros--) : null,
              ),
              SizedBox(
                width: 40,
                child: Text('$_pasajeros', textAlign: TextAlign.center, style: GavText.kpi(context, size: 20)),
              ),
              GavIconButton(
                icon: Icons.add,
                onTap: _pasajeros < 6 ? () => setState(() => _pasajeros++) : null,
              ),
            ],
          ),
        ),
        if (km != null && minutos != null) ...[
          GavKpiGrid(
            children: [
              GavKpiCard(
                label: _rutaCalles != null ? 'Distancia (por calles)' : 'Distancia estimada',
                value: '${km.toStringAsFixed(1).replaceAll('.', ',')} km',
              ),
              GavKpiCard(
                label: _rutaCalles != null ? 'Duración (Google)' : 'Duración estimada',
                value: '$minutos min',
              ),
            ],
          ),
          _PrecioEstimado(km: km, minutos: minutos),
          _ConductoresCerca(origen: o!),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: GavText.body(context, size: 12.5, color: g.danger)),
          ),
        GavPrimaryButton(label: 'Solicitar viaje', loading: _enviando, onPressed: _solicitar),
      ],
    );
  }
}

/// Precio calculado por el backend con la tarifa activa, antes de solicitar.
class _PrecioEstimado extends ConsumerWidget {
  const _PrecioEstimado({required this.km, required this.minutos});
  final double km;
  final int minutos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = context.gav;
    final cotizacion = ref.watch(cotizacionProvider((km: km, minutos: minutos)));
    return GavCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRECIO ESTIMADO', style: GavText.label(context)),
                const SizedBox(height: 4),
                Text(
                  'Tarifa vigente de GAV para este recorrido',
                  style: GavText.body(context, size: 11, color: g.textFaint),
                ),
              ],
            ),
          ),
          cotizacion.when(
            data: (precio) => Text(Fmt.pesos(precio), style: GavText.kpi(context, size: 26, color: g.gold)),
            loading: () => const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, _) => Text('No disponible', style: GavText.body(context, size: 12.5, color: g.textFaint)),
          ),
        ],
      ),
    );
  }
}

class _FilaLugar extends StatelessWidget {
  const _FilaLugar({
    required this.etiqueta,
    required this.lugar,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  final String etiqueta;
  final Lugar? lugar;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icono, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(etiqueta, style: GavText.label(context)),
                    const SizedBox(height: 3),
                    Text(
                      lugar?.nombre ?? 'Seleccionar',
                      style: lugar == null
                          ? GavText.body(context, color: context.gav.textFaint)
                          : GavText.strong(context, size: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.gav.textFaint),
            ],
          ),
        ),
      );
}

class _ConductoresCerca extends ConsumerWidget {
  const _ConductoresCerca({required this.origen});
  final Lugar origen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conductoresCercanosProvider(origen));
    final texto = async.when(
      data: (l) => l.isEmpty
          ? 'No hay conductores cerca en este momento; te asignaremos el próximo disponible.'
          : '${l.length} conductor${l.length == 1 ? '' : 'es'} cerca · el más cercano a '
              '${l.first.distanciaKm.toStringAsFixed(1).replaceAll('.', ',')} km',
      loading: () => 'Buscando conductores cercanos…',
      error: (_, _) => 'No se pudo consultar conductores cercanos.',
    );
    return GavCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const GavIconBox(icon: Icons.local_taxi_outlined, size: 36),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: GavText.body(context, size: 12.5))),
        ],
      ),
    );
  }
}

class _SelectorLugar extends StatefulWidget {
  const _SelectorLugar({required this.titulo, this.buscarEnGoogle = false});
  final String titulo;

  /// Solo para el destino: además del catálogo, busca en Google (Places API New).
  final bool buscarEnGoogle;

  @override
  State<_SelectorLugar> createState() => _SelectorLugarState();
}

class _SelectorLugarState extends State<_SelectorLugar> {
  String _q = '';
  Timer? _espera;
  List<SugerenciaLugar> _google = const [];
  bool _buscando = false;
  bool _resolviendo = false;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    if (widget.buscarEnGoogle) iniciarBusquedaLugares();
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  void _cambio(String v) {
    setState(() {
      _q = v;
      _aviso = null;
    });
    if (!widget.buscarEnGoogle) return;
    _espera?.cancel();
    if (v.trim().length < 3) {
      setState(() {
        _google = const [];
        _buscando = false;
      });
      return;
    }
    // Espera a que el usuario deje de escribir para no llamar a Google en cada letra.
    _espera = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _buscando = true);
      final res = await buscarLugares(v);
      if (!mounted || v != _q) return;
      setState(() {
        _google = res;
        _buscando = false;
      });
    });
  }

  Future<void> _elegirGoogle(SugerenciaLugar s) async {
    setState(() {
      _resolviendo = true;
      _aviso = null;
    });
    final l = await detalleLugar(s);
    if (!mounted) return;
    if (l == null) {
      setState(() {
        _resolviendo = false;
        _aviso = 'No se pudo obtener la ubicación de ese lugar. Prueba con otro.';
      });
      return;
    }
    Navigator.of(context).pop(Lugar(l.nombre, l.nombre, 'OTRO', l.lat, l.lng));
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final catalogo = Lugares.todos
        .where((l) => l.nombre.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    final mostrarGoogle = widget.buscarEnGoogle && _q.trim().length >= 3;

    Widget seccion(String texto) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(texto, style: GavText.label(context)),
        );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.titulo, style: GavText.title(context, size: 22)),
            const SizedBox(height: 12),
            TextField(
              autofocus: false,
              onChanged: _cambio,
              style: GavText.body(context),
              decoration: InputDecoration(
                hintText: widget.buscarEnGoogle ? 'Busca un lugar o dirección en Cartagena' : 'Buscar lugar',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _buscando || _resolviendo
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
            ),
            if (_aviso != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_aviso!, style: GavText.body(context, size: 12, color: g.danger)),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: AbsorbPointer(
                absorbing: _resolviendo,
                child: ListView(
                  children: [
                    if (mostrarGoogle) ...[
                      seccion('RESULTADOS DE GOOGLE'),
                      if (!_buscando && _google.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Sin resultados.', style: GavText.muted(context, size: 12)),
                        ),
                      for (final s in _google)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const GavIconBox(icon: Icons.place_outlined, size: 36),
                          title: Text(s.principal, style: GavText.strong(context, size: 13.5)),
                          subtitle: s.secundario == null
                              ? null
                              : Text(s.secundario!, style: GavText.muted(context, size: 11.5)),
                          onTap: () => _elegirGoogle(s),
                        ),
                    ],
                    if (catalogo.isNotEmpty) ...[
                      if (widget.buscarEnGoogle) seccion('LUGARES FRECUENTES'),
                      for (final l in catalogo)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: GavIconBox(icon: l.icono, size: 36),
                          title: Text(l.nombre, style: GavText.strong(context, size: 13.5)),
                          subtitle: Text(
                            l.categoria.replaceAll('_', ' ').toLowerCase(),
                            style: GavText.muted(context, size: 11.5),
                          ),
                          onTap: () => Navigator.of(context).pop(l),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}