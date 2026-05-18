// Roles tal como los devuelve el backend (con prefijo ROLE_).
export const ROLES = {
  ADMIN: 'ROLE_ADMIN',
  CLIENTE: 'ROLE_CLIENTE',
  CONDUCTOR: 'ROLE_CONDUCTOR',
  RECEPCIONISTA: 'ROLE_RECEPCIONISTA',
};

// Etiqueta legible del rol para el badge del sidebar.
export const ROLE_LABEL = {
  [ROLES.ADMIN]: 'Administrador',
  [ROLES.CLIENTE]: 'Cliente',
  [ROLES.CONDUCTOR]: 'Conductor',
  [ROLES.RECEPCIONISTA]: 'Recepcionista',
};

// Ruta inicial según el rol (tras login y al entrar a "/").
export const HOME_BY_ROLE = {
  [ROLES.ADMIN]: '/admin',
  [ROLES.CLIENTE]: '/cliente',
  [ROLES.CONDUCTOR]: '/conductor',
  [ROLES.RECEPCIONISTA]: '/cliente',
};

// Prefijo de ruta base permitido por rol. Se usa para validar deep-links
// (`from`) tras el login y evitar que un rol aterrice en una zona ajena
// (ej.: un admin enviado a /conductor por un enlace guardado).
export const BASE_PATH_BY_ROLE = {
  [ROLES.ADMIN]: '/admin',
  [ROLES.CLIENTE]: '/cliente',
  [ROLES.CONDUCTOR]: '/conductor',
  [ROLES.RECEPCIONISTA]: '/cliente',
};

// ¿La ruta `path` pertenece a la zona del rol `rol`?
export function isPathAllowedForRole(path, rol) {
  const base = BASE_PATH_BY_ROLE[rol];
  if (!base || !path) return false;
  return path === base || path.startsWith(base + '/');
}

// Destino seguro tras el login: respeta el deep-link `from` solo si es de la
// zona del rol; en caso contrario manda al home del rol.
export function safeRedirectForRole(rol, from) {
  if (from && isPathAllowedForRole(from, rol)) return from;
  return HOME_BY_ROLE[rol] ?? '/login';
}

// Navegación del sidebar por rol. `icon` es el nombre exportado en Icons.jsx.
export const NAV_BY_ROLE = {
  [ROLES.ADMIN]: [
    { to: '/admin', label: 'Estadísticas', icon: 'IconDashboard' },
    { to: '/admin/estadisticas', label: 'Dashboard', icon: 'IconChart' },
    { to: '/admin/conductores', label: 'Conductores', icon: 'IconDrivers' },
    { to: '/admin/clientes', label: 'Clientes', icon: 'IconClients' },
    { to: '/admin/viajes', label: 'Viajes', icon: 'IconTrip' },
    { to: '/admin/asignacion', label: 'Asignación', icon: 'IconActivity' },
    { to: '/admin/notificaciones', label: 'Notificaciones', icon: 'IconBell' },
    { to: '/admin/perfil', label: 'Mi Perfil', icon: 'IconUser' },
  ],
  [ROLES.CLIENTE]: [
    { to: '/cliente', label: 'Solicitar Viaje', icon: 'IconTrip' },
    { to: '/cliente/seguimiento', label: 'Seguimiento', icon: 'IconPin' },
    { to: '/cliente/historial', label: 'Mis Viajes', icon: 'IconActivity' },
    { to: '/cliente/asistente', label: 'Asistente IA', icon: 'IconChat' },
    { to: '/cliente/notificaciones', label: 'Notificaciones', icon: 'IconBell' },
    { to: '/cliente/perfil', label: 'Mi Perfil', icon: 'IconUser' },
  ],
  [ROLES.CONDUCTOR]: [
    { to: '/conductor', label: 'Viaje Activo', icon: 'IconTrip' },
    { to: '/conductor/historial', label: 'Historial', icon: 'IconActivity' },
    { to: '/conductor/ganancias', label: 'Ganancias', icon: 'IconWallet' },
    {
      to: '/conductor/calificaciones',
      label: 'Calificaciones',
      icon: 'IconStarLine',
    },
    {
      to: '/conductor/notificaciones',
      label: 'Notificaciones',
      icon: 'IconBell',
    },
    { to: '/conductor/perfil', label: 'Mi Perfil', icon: 'IconUser' },
  ],
};
