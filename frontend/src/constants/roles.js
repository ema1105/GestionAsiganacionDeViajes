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
