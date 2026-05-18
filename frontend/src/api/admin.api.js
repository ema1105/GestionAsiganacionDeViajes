import api from './axios.js';

// Servicios del rol ADMIN. Mapean los endpoints reales del backend
// (ver SecurityConfig: /api/admin/** requiere ROLE_ADMIN).
export const adminApi = {
  // --- Conductores ---
  listarConductores: (params = {}) =>
    api.get('/admin/conductores', { params }).then((r) => r.data),
  crearConductor: (payload) =>
    api.post('/admin/conductores', payload).then((r) => r.data),
  actualizarConductor: (id, payload) =>
    api.put(`/admin/conductores/${id}`, payload).then((r) => r.data),
  eliminarConductor: (id) =>
    api.delete(`/admin/conductores/${id}`).then((r) => r.data),
  deshabilitarConductor: (id) =>
    api.post(`/admin/conductores/${id}/deshabilitar`).then((r) => r.data),
  habilitarConductor: (id) =>
    api.post(`/admin/conductores/${id}/habilitar`).then((r) => r.data),

  // --- Clientes (endpoint asumido; degrada a [] si no existe aún) ---
  listarClientes: () =>
    api.get('/admin/clientes').then((r) => r.data).catch(() => []),

  // --- Viajes y estadísticas ---
  listarViajes: (params = {}) =>
    api.get('/admin/viajes', { params }).then((r) => r.data),
  gananciasDia: (fecha) =>
    api
      .get('/admin/estadisticas/ganancias/dia', { params: { fecha } })
      .then((r) => r.data),
  gananciasMes: (anio, mes) =>
    api
      .get('/admin/estadisticas/ganancias/mes', { params: { anio, mes } })
      .then((r) => r.data),
  viajesPorDia: (desde, hasta) =>
    api
      .get('/admin/estadisticas/viajes/por-dia', { params: { desde, hasta } })
      .then((r) => r.data),

  // --- Vehículos ---
  listarVehiculos: () =>
    api.get('/admin/vehiculos').then((r) => r.data),
  crearVehiculo: (payload) =>
    api.post('/admin/vehiculos', payload).then((r) => r.data),
  actualizarVehiculo: (id, payload) =>
    api.put(`/admin/vehiculos/${id}`, payload).then((r) => r.data),
  eliminarVehiculo: (id) =>
    api.delete(`/admin/vehiculos/${id}`).then((r) => r.data),
  asociarVehiculo: (conductorId, vehiculoId) =>
    api
      .post(`/admin/conductores/${conductorId}/vehiculo/${vehiculoId}`)
      .then((r) => r.data),
  desasociarVehiculo: (conductorId) =>
    api
      .delete(`/admin/conductores/${conductorId}/vehiculo`)
      .then((r) => r.data),

  // Categorías de vehículo (endpoint asumido; degrada a [] si no existe).
  listarCategorias: () =>
    api
      .get('/admin/categorias')
      .then((r) => r.data)
      .catch(() => []),

  // --- Perfil del administrador ---
  obtenerPerfil: () =>
    api.get('/admin/perfil').then((r) => r.data).catch(() => null),
  actualizarPerfil: (payload) =>
    api.put('/admin/perfil', payload).then((r) => r.data),

  // --- Modelo matemático de asignación (ILP, microservicio Python) ---
  // POST /api/asignacion/ejecutar → AsignacionResultDTO. No está bajo /admin
  // (SecurityConfig solo exige autenticación), pero se invoca desde el panel admin.
  ejecutarAsignacion: () =>
    api.post('/asignacion/ejecutar').then((r) => r.data),
};
