import api from './axios.js';

// /api/notificaciones/** : cualquier usuario autenticado consulta las suyas.
// Endpoints asumidos sobre el NotificacionController; degradan con seguridad.
export const notificacionesApi = {
  listar: () =>
    api.get('/notificaciones').then((r) => r.data).catch(() => []),
  marcarLeida: (id) =>
    api.post(`/notificaciones/${id}/leer`).then((r) => r.data),
  marcarTodasLeidas: () =>
    api.post('/notificaciones/leer-todas').then((r) => r.data),
};
