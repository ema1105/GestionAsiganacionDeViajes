import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth.js';
import { HOME_BY_ROLE } from '../../constants/roles.js';

// Restringe un grupo de rutas a roles específicos.
// Si el rol del usuario no está permitido, lo redirige a SU dashboard
// (no al login: sí está autenticado, solo no autorizado para esta zona).
export default function RoleGuard({ allowed }) {
  const { user } = useAuth();

  if (!allowed.includes(user?.rol)) {
    const fallback = HOME_BY_ROLE[user?.rol] ?? '/login';
    return <Navigate to={fallback} replace />;
  }

  return <Outlet />;
}
