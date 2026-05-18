import api from './axios.js';

// Capa de servicio para los endpoints públicos de autenticación.
// Mantiene los controllers/pages libres de URLs hardcodeadas.
export const authApi = {
  // POST /api/auth/login  -> { token, nombreUsuario, rol }
  login: async (nombreUsuario, contrasena) => {
    const { data } = await api.post('/auth/login', {
      nombreUsuario,
      contrasena,
    });
    return data;
  },

  // POST /api/auth/register/cliente -> UsuarioResponse
  registerCliente: async (payload) => {
    const { data } = await api.post('/auth/register/cliente', payload);
    return data;
  },
};
