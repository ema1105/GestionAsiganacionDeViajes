import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/gav_colors.dart';
import '../../../core/theme/gav_theme.dart';
import '../../../core/ui/formatos.dart';
import '../../../core/ui/gav_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../data/notificaciones_repository.dart';

/// Pantalla "Notificaciones" (admin 07 / conductor 03).
class NotificacionesPage extends ConsumerWidget {
  const NotificacionesPage({super.key, required this.eyebrow});

  /// "GAV · ADMIN" o "GAV · CONDUCTOR".
  final String eyebrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificacionesProvider);
    final hayNoLeidas = async.value?.any((n) => !n.leida) ?? false;

    Future<void> marcarTodas() async {
      try {
        await ref.read(notificacionesRepositoryProvider).marcarTodas();
        ref
          ..invalidate(notificacionesProvider)
          ..invalidate(notificacionesNoLeidasProvider);
      } catch (e) {
        if (context.mounted) showErrorSnack(context, e);
      }
    }

    return GavPage(
      onRefresh: () => ref.refresh(notificacionesProvider.future),
      children: [
        GavTopBar(
          eyebrow: eyebrow,
          title: 'Notificaciones',
          onBack: () => context.pop(),
          trailing: hayNoLeidas
              ? GavIconButton(icon: Icons.done_all, tooltip: 'Marcar todas como leídas', onTap: marcarTodas)
              : null,
        ),
        AsyncValueView<List<Notificacion>>(
          value: async,
          onRetry: () => ref.invalidate(notificacionesProvider),
          isEmpty: (l) => l.isEmpty,
          empty: const Padding(
            padding: EdgeInsets.only(top: 60),
            child: EmptyView(mensaje: 'No hay notificaciones', icono: Icons.notifications_none),
          ),
          data: (lista) => Column(
            children: [
              for (final n in lista) _NotificacionItem(n),
              const SizedBox(height: 8),
              Text('No hay más notificaciones', style: GavText.muted(context, size: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificacionItem extends ConsumerWidget {
  const _NotificacionItem(this.n);
  final Notificacion n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estilo = estiloNotificacion(context, n.tipo);
    return GavNotificationCard(
      icon: estilo.icon,
      iconColor: estilo.color,
      iconBackground: estilo.background,
      title: estilo.titulo,
      description: n.mensaje,
      time: Fmt.relativo(n.fecha),
      unread: !n.leida,
      onTap: n.leida
          ? null
          : () async {
              try {
                await ref.read(notificacionesRepositoryProvider).marcarLeida(n.id);
                ref
                  ..invalidate(notificacionesProvider)
                  ..invalidate(notificacionesNoLeidasProvider);
              } catch (e) {
                if (context.mounted) showErrorSnack(context, e);
              }
            },
    );
  }
}

class EstiloNotificacion {
  const EstiloNotificacion(this.titulo, this.icon, this.color, this.background);
  final String titulo;
  final IconData icon;
  final Color color;
  final Color background;
}

/// Ícono, color y título según `Notificacion.TipoNotificacion` del backend.
EstiloNotificacion estiloNotificacion(BuildContext context, String tipo) {
  final g = context.gav;
  final oro = (g.goldOnContainer, g.goldContainer);
  final ok = (g.success, g.successContainer);
  final mal = (g.danger, g.dangerContainer);
  final (titulo, icon, colores) = switch (tipo) {
    'NUEVA_SOLICITUD' => ('Nueva solicitud de viaje', Icons.schedule, oro),
    'CONDUCTOR_ASIGNADO' => ('Conductor asignado', Icons.person_pin_circle_outlined, ok),
    'CONDUCTOR_EN_CAMINO' => ('Conductor en camino', Icons.directions_car_outlined, oro),
    'VIAJE_ACEPTADO' => ('Viaje aceptado', Icons.check_circle_outline, ok),
    'VIAJE_INICIADO' || 'VIAJE_EN_CURSO' => ('Viaje en curso', Icons.route_outlined, oro),
    'VIAJE_FINALIZADO' => ('Viaje finalizado', Icons.account_balance_wallet_outlined, ok),
    'VIAJE_CANCELADO' => ('Viaje cancelado', Icons.warning_amber_rounded, mal),
    'NUEVA_CALIFICACION' => ('Nueva calificación', Icons.star_border_rounded, oro),
    _ => ('Notificación', Icons.notifications_none, oro),
  };
  return EstiloNotificacion(titulo, icon, colores.$1, colores.$2);
}
