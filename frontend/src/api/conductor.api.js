import api from './axios.js';

// Servicios del rol CONDUCTOR (/api/conductor/** requiere ROLE_CONDUCTOR).
export const conductorApi = {
  solicitudPendiente: () =>
    api
      .get('/conductor/solicitudes/pendiente')
      .then((r) => r.data)
      .catch(() => null),
  responder: (viajeId, aceptar) =>
    api
      .post(`/conductor/viajes/${viajeId}/responder`, null, {
        params: { aceptar },
      })
      .then((r) => r.data),
  viajeActivo: () =>
    api.get('/conductor/viaje-activo').then((r) => r.data).catch(() => null),
  enCamino: (id) =>
    api.post(`/conductor/viajes/${id}/en-camino`).then((r) => r.data),
  iniciar: (id) =>
    api.post(`/conductor/viajes/${id}/iniciar`).then((r) => r.data),
  finalizar: (id) =>
    api.post(`/conductor/viajes/${id}/finalizar`).then((r) => r.data),
  obtenerPerfil: () => api.get('/conductor/perfil').then((r) => r.data),
  actualizarPerfil: (payload) =>
    api.put('/conductor/perfil', payload).then((r) => r.data),

  // --- Historial de viajes (paginado, filtrable) ---
  historialViajes: (params = {}) =>
    api.get('/conductor/viajes', { params }).then((r) => r.data),

  // --- Estadísticas de ganancias / viajes ---
  gananciasDia: (fecha) =>
    api
      .get('/conductor/estadisticas/ganancias/dia', { params: { fecha } })
      .then((r) => r.data),
  gananciasMes: (anio, mes) =>
    api
      .get('/conductor/estadisticas/ganancias/mes', {
        params: { anio, mes },
      })
      .then((r) => r.data),
  viajesDia: (fecha) =>
    api
      .get('/conductor/estadisticas/viajes/dia', { params: { fecha } })
      .then((r) => r.data),
  viajesMes: (anio, mes) =>
    api
      .get('/conductor/estadisticas/viajes/mes', { params: { anio, mes } })
      .then((r) => r.data),

  // Calificar al cliente al cerrar el viaje (CONDUCTOR_A_CLIENTE).
  calificarCliente: (viajeId, payload) =>
    api
      .post(`/conductor/viajes/${viajeId}/calificar-cliente`, payload)
      .then((r) => r.data),

  // --- Calificaciones recibidas ---
  calificaciones: (params = {}) =>
    api
      .get('/conductor/calificaciones', { params })
      .then((r) => r.data),
  promedioCalificaciones: () =>
    api
      .get('/conductor/calificaciones/promedio')
      .then((r) => r.data)
      .catch(() => ({ promedio: 0, totalCalificaciones: 0 })),
};
