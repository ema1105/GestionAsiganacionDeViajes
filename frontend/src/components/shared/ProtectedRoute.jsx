import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth.js';
import Spinner from '../ui/Spinner.jsx';

// Bloquea el acceso a rutas privadas si no hay sesión.
// Mientras AuthContext rehidrata desde localStorage muestra un spinner
// para evitar un parpadeo que rebote al login en cada recarga.
export default function ProtectedRoute() {
  const { isAuthenticated, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <Spinner />
      </div>
    );
  }

  if (!isAuthenticated) {
    // Guarda la ruta de origen para volver tras el login.
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  return <Outlet />;
}
