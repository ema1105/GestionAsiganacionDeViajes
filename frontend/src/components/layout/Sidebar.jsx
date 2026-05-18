import { NavLink } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth.js';
import { NAV_BY_ROLE, ROLE_LABEL } from '../../constants/roles.js';
import * as Icons from '../icons/Icons.jsx';
import { GavLogo, IconLogout } from '../icons/Icons.jsx';

// Sidebar fijo de 240px: branding, badge de rol, navegación por rol y
// footer con el usuario. En móvil se controla con `open`/`onClose`.
export default function Sidebar({ open, onClose }) {
  const { user, logout } = useAuth();
  const nav = NAV_BY_ROLE[user?.rol] ?? [];

  const iniciales = (user?.nombreUsuario ?? '?')
    .slice(0, 2)
    .toUpperCase();

  return (
    <>
      {/* Overlay móvil */}
      {open && (
        <div
          className="fixed inset-0 z-30 bg-black/60 md:hidden"
          onClick={onClose}
        />
      )}

      <aside
        className={`fixed z-40 flex h-screen w-60 flex-col border-r border-line-soft bg-sidebar
          transition-transform duration-300 md:translate-x-0
          ${open ? 'translate-x-0' : '-translate-x-full'}`}
      >
        {/* Branding */}
        <div className="flex items-center gap-3 px-6 py-6">
          <GavLogo size={36} />
          <div className="leading-tight">
            <p className="font-serif text-2xl font-semibold text-ink">GAV</p>
            <p className="text-[10px] uppercase tracking-wider text-muted">
              Gestión de Asignación de Viajes
            </p>
          </div>
        </div>

        {/* Badge de rol */}
        <div className="px-6 pb-5">
          <span className="inline-flex rounded-full border border-gold/25 bg-gold/10 px-3 py-1 text-[11px] font-medium text-gold">
            {ROLE_LABEL[user?.rol] ?? 'Usuario'}
          </span>
        </div>

        {/* Navegación */}
        <nav className="flex-1 space-y-1 overflow-y-auto px-3">
          {nav.map((item) => {
            const Icon = Icons[item.icon];
            return (
              <NavLink
                key={item.to}
                to={item.to}
                end
                onClick={onClose}
                className={({ isActive }) =>
                  `flex items-center gap-3 rounded-lg px-3.5 py-2.5 text-sm transition-all duration-200 ${
                    isActive
                      ? 'bg-active text-gold'
                      : 'text-subtle hover:bg-surface hover:text-ink'
                  }`
                }
              >
                {({ isActive }) => (
                  <>
                    <Icon
                      width={18}
                      height={18}
                      className={isActive ? 'text-gold' : ''}
                    />
                    {item.label}
                  </>
                )}
              </NavLink>
            );
          })}
        </nav>

        {/* Footer usuario */}
        <div className="border-t border-line-soft p-4">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 items-center justify-center rounded-full border border-gold/30 bg-gold/10 text-xs font-semibold text-gold">
              {iniciales}
            </div>
            <div className="min-w-0 flex-1 leading-tight">
              <p className="truncate text-sm font-medium text-ink">
                {user?.nombreUsuario}
              </p>
              <p className="truncate text-[11px] text-muted">
                {ROLE_LABEL[user?.rol]}
              </p>
            </div>
            <button
              onClick={logout}
              title="Cerrar sesión"
              className="rounded-lg p-2 text-muted transition-all duration-200 hover:bg-red-500/10 hover:text-red-400"
            >
              <IconLogout width={18} height={18} />
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
