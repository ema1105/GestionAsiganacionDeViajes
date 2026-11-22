import '../../../core/pagination/pagina.dart';
import '../../viajes_cliente/domain/entities/estado_viaje.dart';
import '../../viajes_cliente/domain/entities/viaje.dart';
import 'conductor_models.dart';

/// Oferta de viaje asignada por el FIFO al conductor, pendiente de respuesta.
class SolicitudPendiente {
  const SolicitudPendiente({
    required this.solicitudId,
    required this.viajeId,
    required this.cantidadPasajeros,
    required this.origen,
    required this.destino,
    this.clienteNombre,
    this.precio,
    this.expiraEn,
    this.origenNombre,
    this.destinoNombre,
  });

  final int solicitudId;
  final int viajeId;
  final int cantidadPasajeros;
  final Coordenada origen;
  final Coordenada destino;
  final String? clienteNombre;
  final double? precio;
  final DateTime? expiraEn;
  final String? origenNombre;
  final String? destinoNombre;
}

/// Siguiente transición que puede ejecutar el conductor sobre su viaje activo.
enum AccionConductor {
  enCamino('Voy en camino'),
  iniciar('Iniciar viaje'),
  finalizar('Finalizar viaje');

  const AccionConductor(this.etiqueta);
  final String etiqueta;

  static AccionConductor? siguiente(EstadoViaje estado) => switch (estado) {
        EstadoViaje.aceptado => enCamino,
        EstadoViaje.enCamino => iniciar,
        EstadoViaje.enCurso => finalizar,
        _ => null,
      };
}

abstract interface class ConductorRepository {
  /// Emite la solicitud pendiente (o null) cada Env.pollingInterval.
  Stream<SolicitudPendiente?> observarSolicitudPendiente();

  Future<Viaje?> viajeActivo();

  Future<Viaje> responder(int viajeId, {required bool aceptar});

  Future<Viaje> ejecutar(AccionConductor accion, int viajeId);

  /// Heartbeat GPS. TODO(fase 5): geolocator + servicio en primer plano.
  Future<void> reportarUbicacion(double lat, double lng);

  /// Punto GPS del recorrido de un viaje en curso (lo ve el cliente en Seguimiento).
  Future<void> registrarSeguimiento(int viajeId, double lat, double lng);

  Future<PerfilConductor> perfil();

  Future<PerfilConductor> actualizarPerfil({String? email, String? telefono});

  Future<Ganancias> gananciasDia(DateTime fecha);

  Future<Ganancias> gananciasMes(int anio, int mes);

  Future<Pagina<Viaje>> historial({
    EstadoViaje? estado,
    DateTime? desde,
    DateTime? hasta,
    int page = 0,
    int size = 4,
  });

  Future<Pagina<Calificacion>> calificaciones({int page = 0, int size = 20});

  Future<PromedioCalificacion> promedio();
}