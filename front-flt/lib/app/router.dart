import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/pages/admin_shell.dart';
import '../features/admin/presentation/pages/dashboard_page.dart';
import '../features/admin/presentation/pages/flota_page.dart';
import '../features/admin/presentation/pages/registro_usuario_admin_page.dart';
import '../features/admin/presentation/pages/historico_page.dart';
import '../features/admin/presentation/pages/inicio_admin_page.dart';
import '../features/admin/presentation/pages/perfil_admin_page.dart';
import '../features/admin/presentation/pages/viajes_admin_page.dart';
import '../features/auth/domain/entities/sesion.dart';
import '../features/auth/presentation/controllers/sesion_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/misc_pages.dart';
import '../features/conductor/presentation/pages/conductor_shell.dart';
import '../features/conductor/presentation/pages/ganancias_page.dart';
import '../features/conductor/presentation/pages/historial_conductor_page.dart';
import '../features/conductor/presentation/pages/panel_page.dart';
import '../features/conductor/presentation/pages/perfil_conductor_page.dart';
import '../features/conductor/presentation/pages/resenas_page.dart';
import '../features/conductor/presentation/pages/viaje_conductor_page.dart';
import '../features/notificaciones/presentation/notificaciones_page.dart';
import '../features/prediccion/domain/periodo.dart';
import '../features/prediccion/presentation/pages/detalle_periodo_page.dart';
import '../features/prediccion/presentation/pages/modelo_predictivo_page.dart';
import '../features/prediccion/presentation/pages/prediccion_page.dart';
import '../features/viajes_cliente/presentation/pages/asistente_page.dart';
import '../features/viajes_cliente/presentation/pages/cliente_shell.dart';
import '../features/viajes_cliente/presentation/pages/inicio_cliente_page.dart';
import '../features/viajes_cliente/presentation/pages/perfil_cliente_page.dart';
import '../features/viajes_cliente/presentation/pages/seguimiento_page.dart';
import '../features/viajes_cliente/presentation/pages/solicitar_viaje_page.dart';
import '../features/viajes_cliente/presentation/pages/viajes_cliente_page.dart';

GoRoute _ruta(String path, Widget Function() page) =>
    GoRoute(path: path, builder: (_, _) => page());

StatefulShellBranch _rama(String path, Widget Function() page) =>
    StatefulShellBranch(routes: [_ruta(path, page)]);

/// Router con protección por rol. Se re-evalúa cada vez que cambia la sesión.
final routerProvider = Provider<GoRouter>((ref) {
  final sesion = ValueNotifier<AsyncValue<Sesion?>>(const AsyncLoading());
  ref.listen<AsyncValue<Sesion?>>(
    sesionControllerProvider,
    (_, next) => sesion.value = next,
    fireImmediately: true,
  );

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: sesion,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final s = sesion.value;
      final loc = state.matchedLocation;

      // Leyendo la sesión guardada al arrancar.
      if (s.isLoading && !s.hasValue) return loc == '/splash' ? null : '/splash';

      final usuario = s.value;
      if (usuario == null) return loc == '/login' ? null : '/login';

      final home = usuario.rol.homePath;
      if (loc == '/login' || loc == '/splash' || !loc.startsWith(home)) return home;
      return null;
    },
    routes: [
      _ruta('/splash', SplashPage.new),
      _ruta('/login', LoginPage.new),
      _ruta('/no-soportado', RolNoSoportadoPage.new),

      // ───── Admin (mockups 01–11) ─────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdminShell(shell: shell),
        branches: [
          _rama('/admin', InicioAdminPage.new),
          _rama('/admin/prediccion', PrediccionPage.new),
          _rama('/admin/historico', HistoricoPage.new),
          _rama('/admin/perfil', PerfilAdminPage.new),
        ],
      ),
      _ruta('/admin/notificaciones', () => const NotificacionesPage(eyebrow: 'GAV · Admin')),
      _ruta('/admin/flota', FlotaPage.new),
      _ruta('/admin/flota/nuevo', RegistroUsuarioAdminPage.new),
      _ruta('/admin/viajes', ViajesAdminPage.new),
      _ruta('/admin/dashboard', DashboardPage.new),
      _ruta('/admin/prediccion/modelo', ModeloPredictivoPage.new),
      GoRoute(
        path: '/admin/prediccion/detalle',
        builder: (_, st) => DetallePeriodoPage(periodo: Periodo.tryParse(st.uri.queryParameters['periodo'])),
      ),

      // ───── Conductor (mockups 01–07) ─────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ConductorShell(shell: shell),
        branches: [
          _rama('/conductor', PanelConductorPage.new),
          _rama('/conductor/viaje', ViajeConductorPage.new),
          _rama('/conductor/historial', HistorialConductorPage.new),
          _rama('/conductor/ganancias', GananciasPage.new),
          _rama('/conductor/resenas', ResenasPage.new),
          _rama('/conductor/perfil', PerfilConductorPage.new),
        ],
      ),
      _ruta('/conductor/notificaciones', () => const NotificacionesPage(eyebrow: 'GAV · Conductor')),

      // ───── Cliente (mismo estilo que admin y conductor) ─────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ClienteShell(shell: shell),
        branches: [
          _rama('/cliente', InicioClientePage.new),
          _rama('/cliente/viajes', ViajesClientePage.new),
          _rama('/cliente/asistente', AsistentePage.new),
          _rama('/cliente/perfil', PerfilClientePage.new),
        ],
      ),
      GoRoute(
        path: '/cliente/solicitar',
        builder: (_, st) => SolicitarViajePage(destinoInicial: st.extra as String?),
      ),
      GoRoute(
        path: '/cliente/seguimiento/:id',
        builder: (_, st) => SeguimientoPage(viajeId: int.parse(st.pathParameters['id']!)),
      ),
      _ruta('/cliente/notificaciones', () => const NotificacionesPage(eyebrow: 'GAV · Cliente')),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    sesion.dispose();
  });
  return router;
});
