import axios from 'axios';

// Clave única bajo la que se persiste el JWT en localStorage.
// Se exporta para que AuthContext use exactamente la misma.
export const TOKEN_KEY = 'gav_token';

// Instancia central de Axios. Todas las llamadas al backend pasan por aquí,
// así los interceptores aplican a toda la app de forma consistente.
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: { 'Content-Type': 'application/json' },
});

// REQUEST: adjunta SIEMPRE el token JWT como `Bearer <token>` si existe uno
// almacenado. Se normaliza (trim) para evitar headers inválidos por espacios o
// saltos de línea accidentales en localStorage.
api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token && token.trim()) {
    config.headers = config.headers ?? {};
    config.headers.Authorization = `Bearer ${token.trim()}`;
  } else {
    // Sin token: nos aseguramos de no enviar un header Authorization viejo.
    if (config.headers) delete config.headers.Authorization;
  }
  return config;
});

// Dedupe de 403 ya logueados (clave método:url) para no inundar la consola.
const warned403 = new Set();

// RESPONSE: normaliza errores y maneja el 401 global.
// Si el backend responde 401 (token expirado/ inválido), se limpia la sesión
// y se redirige al login, evitando estados zombie en la UI.
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;

    // 401 = sesión inválida/expirada (token ausente, vencido o firma inválida).
    // El backend ahora responde 401 (no 403) en estos casos: limpiamos la
    // sesión y redirigimos al login para evitar estados zombie.
    if (status === 401) {
      localStorage.removeItem(TOKEN_KEY);
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }

    // 403 = autenticado pero sin el rol requerido. NO se cierra sesión (el
    // usuario sigue siendo válido). Para evitar SPAM en consola (polling,
    // dashboards), se loguea UNA sola vez por endpoint con nivel debug.
    if (status === 403) {
      const key = `${error.config?.method}:${error.config?.url}`;
      if (!warned403.has(key)) {
        warned403.add(key);
        // eslint-disable-next-line no-console
        console.debug(
          '[403] Acceso denegado a',
          error.config?.url,
          '—',
          error.response?.data?.mensaje || 'sin permiso para tu rol'
        );
      }
    }

    // Mensaje legible: el backend devuelve { mensaje, error, status }
    const mensaje =
      error.response?.data?.mensaje ||
      error.response?.data?.error ||
      error.message ||
      'Error de conexión con el servidor';

    return Promise.reject({ status, mensaje, data: error.response?.data });
  }
);

export default api;
