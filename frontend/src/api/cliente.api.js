import api from './axios.js';

// Servicios del rol CLIENTE (/api/cliente/** requiere ROLE_CLIENTE).
export const clienteApi = {
  solicitarViaje: (payload) =>
    api.post('/cliente/viajes', payload).then((r) => r.data),
  viajeActivo: () =>
    api.get('/cliente/viaje-activo').then((r) => r.data).catch(() => null),
  listarViajes: (params = {}) =>
    api.get('/cliente/viajes', { params }).then((r) => r.data),
  cancelarViaje: (id, motivo) =>
    api
      .post(`/cliente/viajes/${id}/cancelar`, { motivo })
      .then((r) => r.data),
  obtenerPerfil: () => api.get('/cliente/perfil').then((r) => r.data),
  actualizarPerfil: (payload) =>
    api.put('/cliente/perfil', payload).then((r) => r.data),

  // Detalle expandido del viaje (conductor + vehículo).
  detalleViaje: (id) =>
    api
      .get(`/cliente/viajes/${id}/detalle`)
      .then((r) => r.data)
      .catch(() => null),

  // Calificar al conductor tras finalizar el viaje.
  calificarConductor: (viajeId, payload) =>
    api
      .post(`/cliente/viajes/${viajeId}/calificar`, payload)
      .then((r) => r.data),

  // Último punto GPS del viaje (seguimiento en tiempo real).
  seguimientoUltima: (viajeId) =>
    api
      .get(`/cliente/viajes/${viajeId}/seguimiento/ultima`)
      .then((r) => r.data)
      .catch(() => null),

  // Asistente IA (chatbot Gemini). POST /cliente/chatbot/mensaje.
  chatbotMensaje: (mensaje) =>
    api
      .post('/cliente/chatbot/mensaje', { mensaje })
      .then((r) => r.data),

  // Lugares más solicitados (sugerencias para el asistente).
  lugaresMasSolicitados: (limite = 6) =>
    api
      .get('/cliente/lugares/mas-solicitados', { params: { limite } })
      .then((r) => r.data)
      .catch(() => []),
};
