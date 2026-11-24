import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/ui/gav_widgets.dart';

/// Contenedor con la barra inferior del conductor:
/// Activo · Viaje · Historial · Ganancias · Reseñas · Perfil.
class ConductorShell extends StatelessWidget {
  const ConductorShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const items = [
    GavNavItem(Icons.directions_car_outlined, 'Activo'),
    GavNavItem(Icons.route_outlined, 'Viaje'),
    GavNavItem(Icons.schedule, 'Historial'),
    GavNavItem(Icons.account_balance_wallet_outlined, 'Ganancias'),
    GavNavItem(Icons.star_border_rounded, 'Reseñas'),
    GavNavItem(Icons.person_outline, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: GavBottomNav(
          items: items,
          index: shell.currentIndex,
          onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        ),
      );
}
