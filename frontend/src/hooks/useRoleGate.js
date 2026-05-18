import { useAuth } from './useAuth.js';

// Defensa en profundidad por DEBAJO de RoleGuard.
//
// RoleGuard ya impide montar rutas de un rol ajeno, pero un componente
// específico de rol (dashboards con polling, efectos de carga) NO debe
// disparar NUNCA sus requests Axios si el rol autenticado no coincide,
// aunque por un deep-link, un intervalo huérfano o un montaje transitorio
// llegara a renderizarse.
//
// Uso:
//   const { authorized } = useRoleGate(ROLES.CONDUCTOR);
//   useEffect(() => { if (!authorized) return; cargar(); }, [authorized]);
export function useRoleGate(expectedRole) {
  const { user, loading } = useAuth();
  const rol = user?.rol ?? null;
  const authorized = !loading && rol === expectedRole;
  return { authorized, rol, loading };
}
