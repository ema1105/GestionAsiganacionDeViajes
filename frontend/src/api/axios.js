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

// REQUEST: adjunta el token JWT como Bearer en cada petición si existe.
api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// RESPONSE: normaliza errores y maneja el 401 global.
// Si el backend responde 401 (token expirado/ inválido), se limpia la sesión
// y se redirige al login, evitando estados zombie en la UI.
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;

    if (status === 401) {
      localStorage.removeItem(TOKEN_KEY);
      // Evita bucle de redirección si ya estamos en /login
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
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
