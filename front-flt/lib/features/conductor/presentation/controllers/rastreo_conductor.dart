import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/config/env.dart';
import '../../../../core/location/ubicacion.dart';
import '../../../auth/presentation/controllers/sesion_controller.dart';
import '../../data/conductor_repository_impl.dart';
import 'conductor_providers.dart';

class EstadoRastreo {
  const EstadoRastreo({this.permiso, this.activo = false, this.ultimoEnvio, this.lat, this.lng, this.error});

  final EstadoPermiso? permiso;
  final bool activo;
  final DateTime? ultimoEnvio;
  final double? lat;
  final double? lng;
  final String? error;

  EstadoRastreo copyWith({
    EstadoPermiso? permiso,
    bool? activo,
    DateTime? ultimoEnvio,
    double? lat,
    double? lng,
    String? error,
  }) =>
      EstadoRastreo(
        permiso: permiso ?? this.permiso,
        activo: activo ?? this.activo,
        ultimoEnvio: ultimoEnvio ?? this.ultimoEnvio,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        error: error,
      );
}

/// Comparte la ubicación del conductor con el backend:
/// - POST /api/conductor/ubicacion  → conductores cercanos y asignación.
/// - POST /api/conductor/viajes/{id}/seguimiento → mapa del cliente durante el viaje.
/// Sigue activo mientras haya sesión (no se detiene al cambiar de pestaña).
class RastreoConductor extends Notifier<EstadoRastreo> {
  StreamSubscription<Position>? _sub;
  Timer? _latido;
  Position? _ultima;

  @override
  EstadoRastreo build() {
    ref
      ..onDispose(_cancelar)
      ..listen(sesionControllerProvider, (_, s) {
        if (s.value == null) detener();
      });
    return const EstadoRastreo();
  }

  Future<void> activar() async {
    final permiso = await Ubicacion.solicitarPermiso();
    if (!permiso.ok) {
      state = state.copyWith(permiso: permiso, activo: false);
      return;
    }
    _cancelar();
    state = state.copyWith(permiso: permiso, activo: true);
    _sub = Ubicacion.seguir().listen(
      (p) {
        _ultima = p;
        _enviar(p);
      },
      onError: (Object _) => state = state.copyWith(error: 'Se perdió la señal GPS.'),
    );
    // Latido: reenvía la última posición aunque el conductor esté detenido.
    _latido = Timer.periodic(Env.intervaloUbicacion, (_) {
      final p = _ultima;
      if (p != null) _enviar(p, forzar: true);
    });
    final inicial = await Ubicacion.actual();
    if (inicial != null) {
      _ultima = inicial;
      await _enviar(inicial, forzar: true);
    }
  }

  void detener() {
    _cancelar();
    state = state.copyWith(activo: false);
  }

  void _cancelar() {
    _sub?.cancel();
    _sub = null;
    _latido?.cancel();
    _latido = null;
  }

  Future<void> _enviar(Position p, {bool forzar = false}) async {
    final ultimo = state.ultimoEnvio;
    if (!forzar && ultimo != null && DateTime.now().difference(ultimo) < Env.intervaloUbicacion) return;
    final repo = ref.read(conductorRepositoryProvider);
    try {
      await repo.reportarUbicacion(p.latitude, p.longitude);
      final viaje = ref.read(viajeActivoConductorProvider).value;
      if (viaje != null && viaje.estado.enProceso) {
        await repo.registrarSeguimiento(viaje.id, p.latitude, p.longitude);
      }
      state = state.copyWith(ultimoEnvio: DateTime.now(), lat: p.latitude, lng: p.longitude);
    } catch (_) {
      state = state.copyWith(error: 'No se pudo enviar la ubicación; se reintentará.');
    }
  }
}

final rastreoConductorProvider = NotifierProvider<RastreoConductor, EstadoRastreo>(RastreoConductor.new);
