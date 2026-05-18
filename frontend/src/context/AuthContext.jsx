import { createContext, useState, useEffect, useCallback } from 'react';
import { authApi } from '../api/auth.api.js';
import { TOKEN_KEY } from '../api/axios.js';
import { decodeToken, isTokenExpired } from '../utils/jwt.js';

export const AuthContext = createContext(null);

// Provee el estado de autenticación a toda la app.
// El JWT se persiste en localStorage para sobrevivir recargas (sesión persistente).
// Al montar, se rehidrata desde localStorage validando expiración.
export function AuthProvider({ children }) {
  const [user, setUser] = useState(null); // { nombreUsuario, rol }
  const [loading, setLoading] = useState(true); // true mientras se rehidrata

  // Rehidratación inicial: si hay token válido en localStorage, restaura el user.
  useEffect(() => {
    const token = localStorage.getItem(TOKEN_KEY);
    if (token && !isTokenExpired(token)) {
      const claims = decodeToken(token);
      setUser({
        nombreUsuario: claims?.sub ?? null,
        rol: claims?.rol ?? null,
      });
    } else {
      localStorage.removeItem(TOKEN_KEY);
    }
    setLoading(false);
  }, []);

  // Login: llama al backend, persiste el token y deriva el user del JWT.
  const login = useCallback(async (nombreUsuario, contrasena) => {
    const data = await authApi.login(nombreUsuario, contrasena);
    localStorage.setItem(TOKEN_KEY, data.token);
    const claims = decodeToken(data.token);
    setUser({
      nombreUsuario: data.nombreUsuario ?? claims?.sub ?? null,
      rol: data.rol ?? claims?.rol ?? null,
    });
    return data;
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY);
    setUser(null);
  }, []);

  const value = {
    user,
    loading,
    isAuthenticated: !!user,
    login,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
