import api from './axios.js';

// /api/notificaciones/** : cualquier usuario autenticado consulta las suyas.
// Rutas alineadas EXACTAMENTE con NotificacionController del backend:
//   GET  /api/notificaciones/mias
//   GET  /api/notificaciones/no-leidas
//   GET  /api/notificaciones/no-leidas/count
//   PUT  /api/notificaciones/{id}/leer
//   PUT  /api/notificaciones/leer-todas
export const notificacionesApi = {
  listar: () =>
    api.get('/notificaciones/mias').then((r) => r.data).catch(() => []),
  listarNoLeidas: () =>
    api.get('/notificaciones/no-leidas').then((r) => r.data).catch(() => []),
  contarNoLeidas: () =>
    api
      .get('/notificaciones/no-leidas/count')
      .then((r) => r.data?.count ?? 0)
      .catch(() => 0),
  marcarLeida: (id) =>
    api.put(`/notificaciones/${id}/leer`).then((r) => r.data),
  marcarTodasLeidas: () =>
    api.put('/notificaciones/leer-todas').then((r) => r.data),
};
