import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../notificaciones/data/notificaciones_repository.dart';
import '../admin_providers.dart';

/// Mockup admin 03 · Inicio.
class InicioAdminPage extends ConsumerWidget {
  const InicioAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(resumenInicioProvider);
    final noLeidas = ref.watch(notificacionesNoLeidasProvider).value ?? 0;
    final mes = Fmt.mesCorto(DateTime.now().month).toUpperCase();

    return GavPage(
      onRefresh: () async {
        ref
          ..invalidate(notificacionesNoLeidasProvider)
          ..invalidate(resumenInicioProvider);
        await ref.read(resumenInicioProvider.future);
      },
      children: [
        GavTopBar(
          title: 'Inicio',
          subtitle: 'Resumen de tu operación GAV',
          trailing: GavIconButton(
            icon: Icons.notifications_none,
            badge: noLeidas > 0,
            tooltip: 'Notificaciones',
            onTap: () => context.push('/admin/notificaciones'),
          ),
        ),
        AsyncValueView<ResumenInicio>(
          value: resumen,
          onRetry: () => ref.invalidate(resumenInicioProvider),
          data: (r) {
            final variacion = Fmt.variacion(r.viajesMes, r.viajesMesAnterior);
            return GavKpiGrid(
              children: [
                GavKpiCard(label: 'Viajes $mes ${DateTime.now().year}', value: Fmt.miles(r.viajesMes)),
                GavKpiCard(
                  label: 'Variación vs mes anterior',
                  value: variacion == null ? '—' : formatearPorcentaje(variacion),
                  valueColor: variacion == null
                      ? null
                      : (variacion >= 0 ? context.gav.success : context.gav.danger),
                ),
                GavKpiCard(label: 'Conductores disponibles ahora', value: '${r.conductoresDisponibles}'),
                GavKpiCard(label: 'Viajes hoy', value: '${r.viajesHoy}'),
              ],
            );
          },
        ),
        const GavSectionTitle('Accesos rápidos'),
        GavQuickAccessCard(
          icon: Icons.bar_chart_rounded,
          title: 'Predicción mensual',
          subtitle: 'Consulta la demanda estimada del mes',
          onTap: () => context.go('/admin/prediccion'),
        ),
        GavQuickAccessCard(
          icon: Icons.history,
          title: 'Histórico',
          subtitle: 'Compara meses anteriores',
          onTap: () => context.go('/admin/historico'),
        ),
        GavQuickAccessCard(
          icon: Icons.person_outline,
          title: 'Mi perfil',
          subtitle: 'Gestiona tu cuenta',
          onTap: () => context.go('/admin/perfil'),
        ),
        const GavSectionTitle('Más accesos'),
        GavKpiGrid(
          children: [
            GavTileButton(
              icon: Icons.notifications_none,
              label: 'Notificaciones',
              onTap: () => context.push('/admin/notificaciones'),
            ),
            GavTileButton(
              icon: Icons.local_taxi_outlined,
              label: 'Flota y clientes',
              onTap: () => context.push('/admin/flota'),
            ),
            GavTileButton(
              icon: Icons.route_outlined,
              label: 'Viajes',
              onTap: () => context.push('/admin/viajes'),
            ),
            GavTileButton(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard BI',
              onTap: () => context.push('/admin/dashboard'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Datos en tiempo real del backend GAV · se actualizan al deslizar hacia abajo',
          style: GavText.body(context, size: 10.5, color: context.gav.textFaint),
        ),
      ],
    );
  }
}
