import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth.js';
import { ROLES, HOME_BY_ROLE } from '../constants/roles.js';
import ProtectedRoute from '../components/shared/ProtectedRoute.jsx';
import RoleGuard from '../components/shared/RoleGuard.jsx';
import DashboardLayout from '../layouts/DashboardLayout.jsx';
import LoginPage from '../pages/auth/LoginPage.jsx';
import AdminDashboardPage from '../pages/admin/DashboardPage.jsx';
import EstadisticasPage from '../pages/admin/EstadisticasPage.jsx';
import ConductoresPage from '../pages/admin/ConductoresPage.jsx';
import VehiculosPage from '../pages/admin/VehiculosPage.jsx';
import ClientesPage from '../pages/admin/ClientesPage.jsx';
import ViajesPage from '../pages/admin/ViajesPage.jsx';
import ClienteDashboardPage from '../pages/cliente/DashboardPage.jsx';
import ClienteSeguimientoPage from '../pages/cliente/SeguimientoPage.jsx';
import ClienteHistorialPage from '../pages/cliente/HistorialPage.jsx';
import ClienteChatbotPage from '../pages/cliente/ChatbotPage.jsx';
import ConductorDashboardPage from '../pages/conductor/DashboardPage.jsx';
import ConductorHistorialPage from '../pages/conductor/HistorialPage.jsx';
import ConductorGananciasPage from '../pages/conductor/GananciasPage.jsx';
import ConductorCalificacionesPage from '../pages/conductor/CalificacionesPage.jsx';
import NotificacionesPage from '../pages/shared/NotificacionesPage.jsx';
import PerfilPage from '../pages/shared/PerfilPage.jsx';
import NotFoundPage from '../pages/NotFoundPage.jsx';

function RootRedirect() {
  const { isAuthenticated, user } = useAuth();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return <Navigate to={HOME_BY_ROLE[user?.rol] ?? '/login'} replace />;
}

export default function AppRouter() {
  return (
    <Routes>
      <Route path="/" element={<RootRedirect />} />
      <Route path="/login" element={<LoginPage />} />

      {/* Zona privada: sesión + layout con sidebar */}
      <Route element={<ProtectedRoute />}>
        <Route element={<DashboardLayout />}>
          {/* ADMIN */}
          <Route element={<RoleGuard allowed={[ROLES.ADMIN]} />}>
            <Route path="/admin" element={<AdminDashboardPage />} />
            <Route
              path="/admin/estadisticas"
              element={<EstadisticasPage />}
            />
            <Route path="/admin/conductores" element={<ConductoresPage />} />
            <Route path="/admin/vehiculos" element={<VehiculosPage />} />
            <Route path="/admin/clientes" element={<ClientesPage />} />
            <Route path="/admin/viajes" element={<ViajesPage />} />
            <Route
              path="/admin/notificaciones"
              element={<NotificacionesPage />}
            />
            <Route path="/admin/perfil" element={<PerfilPage />} />
          </Route>

          {/* CLIENTE */}
          <Route element={<RoleGuard allowed={[ROLES.CLIENTE, ROLES.RECEPCIONISTA]} />}>
            <Route path="/cliente" element={<ClienteDashboardPage />} />
            <Route
              path="/cliente/seguimiento"
              element={<ClienteSeguimientoPage />}
            />
            <Route
              path="/cliente/historial"
              element={<ClienteHistorialPage />}
            />
            <Route
              path="/cliente/asistente"
              element={<ClienteChatbotPage />}
            />
            <Route
              path="/cliente/notificaciones"
              element={<NotificacionesPage />}
            />
            <Route path="/cliente/perfil" element={<PerfilPage />} />
          </Route>

          {/* CONDUCTOR */}
          <Route element={<RoleGuard allowed={[ROLES.CONDUCTOR]} />}>
            <Route path="/conductor" element={<ConductorDashboardPage />} />
            <Route
              path="/conductor/historial"
              element={<ConductorHistorialPage />}
            />
            <Route
              path="/conductor/ganancias"
              element={<ConductorGananciasPage />}
            />
            <Route
              path="/conductor/calificaciones"
              element={<ConductorCalificacionesPage />}
            />
            <Route
              path="/conductor/notificaciones"
              element={<NotificacionesPage />}
            />
            <Route path="/conductor/perfil" element={<PerfilPage />} />
          </Route>
        </Route>
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}
