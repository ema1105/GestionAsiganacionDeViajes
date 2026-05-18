import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from '../components/layout/Sidebar.jsx';
import { IconMenu } from '../components/icons/Icons.jsx';

// Layout global de dos columnas. Sidebar fijo (240px) + contenedor principal
// dinámico. El sidebar se oculta en móvil y se abre con el botón hamburguesa.
export default function DashboardLayout() {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <div className="flex min-h-screen bg-panel">
      <Sidebar open={mobileOpen} onClose={() => setMobileOpen(false)} />

      <div className="flex min-h-screen flex-1 flex-col md:ml-60">
        {/* Topbar solo móvil */}
        <header className="flex items-center gap-3 border-b border-line bg-sidebar px-4 py-3 md:hidden">
          <button
            onClick={() => setMobileOpen(true)}
            className="text-subtle hover:text-ink"
            aria-label="Abrir menú"
          >
            <IconMenu />
          </button>
          <span className="font-serif text-lg text-ink">GAV</span>
        </header>

        <main className="flex-1 p-6 lg:p-10">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
