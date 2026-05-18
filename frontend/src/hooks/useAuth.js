import { useContext } from 'react';
import { AuthContext } from '../context/AuthContext.jsx';

// Hook de acceso al contexto de autenticación.
// Lanza si se usa fuera de <AuthProvider> para detectar errores de montaje.
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (ctx === null) {
    throw new Error('useAuth debe usarse dentro de <AuthProvider>');
  }
  return ctx;
}
