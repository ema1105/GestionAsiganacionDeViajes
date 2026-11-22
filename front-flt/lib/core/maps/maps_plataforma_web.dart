import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:web/web.dart' as web;

import 'lugar_google.dart';
import 'ruta_calculada.dart';

Future<bool>? _carga;

/// Centro de Cartagena: sesgo de las búsquedas para que salgan resultados locales.
const _centroLat = 10.4236;
const _centroLng = -75.5300;
const _radioBusquedaMetros = 30000.0;

JSObject? get _maps {
  final google = globalContext.getProperty<JSObject?>('google'.toJS);
  if (google == null || !google.has('maps')) return null;
  return google.getProperty<JSObject?>('maps'.toJS);
}

bool get _mapsListo => _maps != null;

/// Inyecta el script de la Maps JavaScript API una sola vez (como useGoogleMaps.js del React).
Future<bool> cargarGoogleMaps(String apiKey) {
  if (_mapsListo) return Future.value(true);
  if (apiKey.isEmpty) return Future.value(false);
  return _carga ??= _inyectar(apiKey);
}

Future<bool> _inyectar(String apiKey) {
  final completer = Completer<bool>();
  final script = web.HTMLScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey'
        '&libraries=geometry,places&language=es&region=CO'
    ..async = true;
  script.onload = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(_mapsListo);
  }).toJS;
  script.onerror = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(false);
  }).toJS;
  web.document.head!.append(script);
  return completer.future.timeout(const Duration(seconds: 15), onTimeout: () => false);
}

// ---------------------------------------------------------------------------
// Utilidades de interop
// ---------------------------------------------------------------------------

/// Objeto JS a partir de pares clave → valor ya convertidos.
JSObject _obj(Map<String, JSAny?> campos) {
  final o = JSObject();
  campos.forEach((k, v) => o.setProperty(k.toJS, v));
  return o;
}

JSObject _latLng(double lat, double lng) => _obj({'lat': lat.toJS, 'lng': lng.toJS});

/// Lee lat/lng tanto si son propiedades (LatLngLiteral, LatLngAltitude)
/// como si son métodos (google.maps.LatLng).
double? _coord(JSObject p, String k) {
  final v = p.getProperty<JSAny?>(k.toJS);
  if (v == null) return null;
  if (v.isA<JSFunction>()) return p.callMethod<JSNumber>(k.toJS).toDartDouble;
  return p.getProperty<JSNumber>(k.toJS).toDartDouble;
}

String? _texto(JSObject o, String campo) =>
    o.getProperty<JSObject?>(campo.toJS)?.getProperty<JSString?>('text'.toJS)?.toDart;

/// google.maps.importLibrary(nombre); si no existe, usa el espacio ya cargado (google.maps.places).
Future<JSObject?> _libreria(String nombre) async {
  final maps = _maps;
  if (maps == null) return null;
  if (maps.has('importLibrary')) {
    try {
      return await maps.callMethod<JSPromise<JSObject>>('importLibrary'.toJS, nombre.toJS).toDart;
    } catch (_) {
      // Continúa con el espacio de nombres cargado por el parámetro `libraries`.
    }
  }
  return maps.getProperty<JSObject?>(nombre.toJS);
}

// ---------------------------------------------------------------------------
// Rutas: primero Routes API (clase Route); si no está habilitada, Directions (legacy).
// ---------------------------------------------------------------------------

/// Ruta por calles. null si ninguna API de rutas está habilitada para la clave o no hay ruta;
/// en ese caso la pantalla usa la estimación por Haversine.
Future<RutaCalculada?> calcularRutaPorCalles(double oLat, double oLng, double dLat, double dLng) async {
  if (!_mapsListo) return null;
  return await _rutaConRoutesApi(oLat, oLng, dLat, dLng) ??
      await _rutaConDirections(oLat, oLng, dLat, dLng);
}

Future<RutaCalculada?> _rutaConRoutesApi(double oLat, double oLng, double dLat, double dLng) async {
  try {
    final routes = await _libreria('routes');
    final claseRoute = routes?.getProperty<JSObject?>('Route'.toJS);
    if (claseRoute == null) return null;
    final request = _obj({
      'origin': _latLng(oLat, oLng),
      'destination': _latLng(dLat, dLng),
      'travelMode': 'DRIVING'.toJS,
      'fields': ['path', 'distanceMeters', 'durationMillis'].jsify(),
    });
    final res = await claseRoute.callMethod<JSPromise<JSObject>>('computeRoutes'.toJS, request).toDart;
    final lista = res.getProperty<JSArray<JSObject>?>('routes'.toJS)?.toDart ?? const [];
    if (lista.isEmpty) return null;
    final ruta = lista.first;
    final metros = ruta.getProperty<JSNumber?>('distanceMeters'.toJS)?.toDartDouble;
    final ms = ruta.getProperty<JSNumber?>('durationMillis'.toJS)?.toDartDouble;
    final path = ruta.getProperty<JSArray<JSObject>?>('path'.toJS)?.toDart ?? const [];
    if (metros == null || ms == null) return null;
    final puntos = <LatLng>[];
    for (final p in path) {
      final lat = _coord(p, 'lat'), lng = _coord(p, 'lng');
      if (lat != null && lng != null) puntos.add(LatLng(lat, lng));
    }
    return RutaCalculada(
      km: double.parse((metros / 1000).toStringAsFixed(2)),
      minutos: (ms / 60000).ceil(),
      puntos: puntos,
    );
  } catch (_) {
    return null;
  }
}

@JS('google.maps.DirectionsService')
extension type _DirectionsService._(JSObject _) implements JSObject {
  external _DirectionsService();
  external JSPromise<JSObject> route(JSAny request);
}

/// DirectionsService (mismo método que MapView.jsx del React).
Future<RutaCalculada?> _rutaConDirections(double oLat, double oLng, double dLat, double dLng) async {
  try {
    final request = _obj({
      'origin': _latLng(oLat, oLng),
      'destination': _latLng(dLat, dLng),
      'travelMode': 'DRIVING'.toJS,
    });
    final res = await _DirectionsService().route(request).toDart;
    final routes = res.getProperty<JSArray<JSObject>>('routes'.toJS).toDart;
    if (routes.isEmpty) return null;
    final ruta = routes.first;
    final legs = ruta.getProperty<JSArray<JSObject>>('legs'.toJS).toDart;
    if (legs.isEmpty) return null;
    final leg = legs.first;
    final metros = leg.getProperty<JSObject>('distance'.toJS).getProperty<JSNumber>('value'.toJS).toDartDouble;
    final segundos = leg.getProperty<JSObject>('duration'.toJS).getProperty<JSNumber>('value'.toJS).toDartDouble;
    final polyline = ruta.getProperty<JSString>('overview_polyline'.toJS).toDart;
    return RutaCalculada(
      km: double.parse((metros / 1000).toStringAsFixed(2)),
      minutos: (segundos / 60).ceil(),
      puntos: decodificarPolyline(polyline),
    );
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Búsqueda de lugares: Places API (New) → AutocompleteSuggestion + Place.fetchFields
// ---------------------------------------------------------------------------

/// Token de sesión: Google cobra la búsqueda completa (letras + selección) como una sola sesión.
JSObject? _token;

/// Predicciones de la última búsqueda, para convertirlas en Place al elegir una.
final _predicciones = <String, JSObject>{};

/// Abre una sesión de búsqueda nueva (se llama al abrir el selector de destino).
void iniciarBusquedaLugares() {
  _token = null;
  _predicciones.clear();
}

Future<List<SugerenciaLugar>> buscarLugares(String texto) async {
  final q = texto.trim();
  if (!_mapsListo || q.length < 3) return const [];
  try {
    final places = await _libreria('places');
    final clase = places?.getProperty<JSObject?>('AutocompleteSuggestion'.toJS);
    if (places == null || clase == null) return const [];

    if (_token == null) {
      final ctor = places.getProperty<JSFunction?>('AutocompleteSessionToken'.toJS);
      _token = ctor?.callAsConstructor<JSObject>();
    }

    final request = _obj({
      'input': q.toJS,
      'language': 'es'.toJS,
      'region': 'co'.toJS,
      'includedRegionCodes': ['co'].jsify(),
      'locationBias': _obj({
        'center': _latLng(_centroLat, _centroLng),
        'radius': _radioBusquedaMetros.toJS,
      }),
      if (_token != null) 'sessionToken': _token,
    });

    final res = await clase.callMethod<JSPromise<JSObject>>('fetchAutocompleteSuggestions'.toJS, request).toDart;
    final sugerencias = res.getProperty<JSArray<JSObject>?>('suggestions'.toJS)?.toDart ?? const [];

    _predicciones.clear();
    final resultado = <SugerenciaLugar>[];
    for (final s in sugerencias) {
      final pred = s.getProperty<JSObject?>('placePrediction'.toJS);
      if (pred == null) continue;
      final id = pred.getProperty<JSString?>('placeId'.toJS)?.toDart;
      final principal = _texto(pred, 'mainText') ?? _texto(pred, 'text');
      if (id == null || principal == null) continue;
      _predicciones[id] = pred;
      resultado.add(SugerenciaLugar(placeId: id, principal: principal, secundario: _texto(pred, 'secondaryText')));
    }
    return resultado;
  } catch (_) {
    return const [];
  }
}

/// Coordenadas y nombre del lugar elegido (Place Details). Cierra la sesión de búsqueda.
Future<LugarGoogle?> detalleLugar(SugerenciaLugar sugerencia) async {
  final pred = _predicciones[sugerencia.placeId];
  if (pred == null) return null;
  try {
    final place = pred.callMethod<JSObject>('toPlace'.toJS);
    await place
        .callMethod<JSPromise<JSAny?>>(
          'fetchFields'.toJS,
          _obj({'fields': ['displayName', 'formattedAddress', 'location'].jsify()}),
        )
        .toDart;
    _token = null;

    final loc = place.getProperty<JSObject?>('location'.toJS);
    if (loc == null) return null;
    final lat = _coord(loc, 'lat'), lng = _coord(loc, 'lng');
    if (lat == null || lng == null) return null;
    final nombre = place.getProperty<JSString?>('displayName'.toJS)?.toDart;
    return LugarGoogle(
      nombre: (nombre == null || nombre.isEmpty) ? sugerencia.principal : nombre,
      direccion: place.getProperty<JSString?>('formattedAddress'.toJS)?.toDart,
      lat: lat,
      lng: lng,
    );
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Geocodificación inversa (Geocoding API): punto tocado en el mapa → dirección
// ---------------------------------------------------------------------------

Future<String?> direccionDe(double lat, double lng) async {
  final maps = _maps;
  final ctor = maps?.getProperty<JSFunction?>('Geocoder'.toJS);
  if (ctor == null) return null;
  try {
    final geocoder = ctor.callAsConstructor<JSObject>();
    final res = await geocoder
        .callMethod<JSPromise<JSObject>>(
          'geocode'.toJS,
          _obj({'location': _latLng(lat, lng), 'language': 'es'.toJS}),
        )
        .toDart;
    final resultados = res.getProperty<JSArray<JSObject>?>('results'.toJS)?.toDart ?? const [];
    if (resultados.isEmpty) return null;
    return resultados.first.getProperty<JSString?>('formatted_address'.toJS)?.toDart;
  } catch (_) {
    return null;
  }
}