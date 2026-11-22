/// Rutas del backend Spring Boot de GAV. Un solo lugar para cambiarlas.
abstract final class ApiPaths {
  // Auth (públicas)
  static const authPrefix = '/api/auth/';
  static const login = '/api/auth/login';
  static const registerCliente = '/api/auth/register/cliente';

  // Cliente
  static const clienteViajes = '/api/cliente/viajes';
  static const clienteViajeActivo = '/api/cliente/viaje-activo';
  static String clienteViaje(int id) => '/api/cliente/viajes/$id';
  static String clienteCancelar(int id) => '/api/cliente/viajes/$id/cancelar';
  static String clienteUltimoPunto(int id) => '/api/cliente/viajes/$id/seguimiento/ultima';
  static const clienteConductoresCercanos = '/api/cliente/conductores-cercanos';

  // Conductor
  static const conductorSolicitudPendiente = '/api/conductor/solicitudes/pendiente';
  static const conductorViajeActivo = '/api/conductor/viaje-activo';
  static const conductorUbicacion = '/api/conductor/ubicacion';
  static String conductorResponder(int id) => '/api/conductor/viajes/$id/responder';
  static String conductorEnCamino(int id) => '/api/conductor/viajes/$id/en-camino';
  static String conductorIniciar(int id) => '/api/conductor/viajes/$id/iniciar';
  static String conductorFinalizar(int id) => '/api/conductor/viajes/$id/finalizar';
  static const conductorPerfil = '/api/conductor/perfil';
  static String conductorSeguimiento(int id) => '/api/conductor/viajes/$id/seguimiento';
  static const conductorViajes = '/api/conductor/viajes';
  static const conductorGananciasDia = '/api/conductor/estadisticas/ganancias/dia';
  static const conductorGananciasMes = '/api/conductor/estadisticas/ganancias/mes';
  static const conductorCalificaciones = '/api/conductor/calificaciones';
  static const conductorCalificacionesPromedio = '/api/conductor/calificaciones/promedio';

  // Admin
  static const adminPerfil = '/api/admin/perfil';
  static const adminConductores = '/api/admin/conductores';
  static String adminConductorDeshabilitar(int id) => '/api/admin/conductores/$id/deshabilitar';
  static String adminConductorHabilitar(int id) => '/api/admin/conductores/$id/habilitar';
  static const adminVehiculos = '/api/admin/vehiculos';
  static const adminClientes = '/api/admin/clientes';
  static const adminCategorias = '/api/admin/categorias';
  static const adminViajes = '/api/admin/viajes';
  static const adminGananciasDia = '/api/admin/estadisticas/ganancias/dia';
  static const adminGananciasMes = '/api/admin/estadisticas/ganancias/mes';
  static const adminViajesDia = '/api/admin/estadisticas/viajes/dia';
  static const adminViajesPorDia = '/api/admin/estadisticas/viajes/por-dia';
  static const adminDashboardUrl = '/api/admin/dashboard/url';

  // Notificaciones (cualquier rol autenticado)
  static const notificacionesMias = '/api/notificaciones/mias';
  static const notificacionesNoLeidasCount = '/api/notificaciones/no-leidas/count';
  static const notificacionesLeerTodas = '/api/notificaciones/leer-todas';
  static String notificacionLeer(int id) => '/api/notificaciones/$id/leer';
}
