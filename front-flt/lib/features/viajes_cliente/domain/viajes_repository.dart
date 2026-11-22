import '../../../core/pagination/pagina.dart';
import 'entities/viaje.dart';

abstract interface class ViajesClienteRepository {
  /// Viaje en curso del cliente, o null si no tiene (backend responde 204).
  Future<Viaje?> viajeActivo();

  Future<Pagina<Viaje>> historial(FiltroViajes filtro, {int page = 0, int size = 20});

  Future<void> cancelar(int viajeId);

  /// Última posición del conductor durante el viaje.
  /// Hoy es polling; cuando exista WebSocket solo cambia la implementación.
  Stream<PuntoSeguimiento?> seguirViaje(int viajeId);
}
