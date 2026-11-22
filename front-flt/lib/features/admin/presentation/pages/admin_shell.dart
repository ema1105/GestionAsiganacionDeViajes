import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/ui/gav_widgets.dart';

/// Contenedor con la barra inferior del admin: Inicio · Predicción · Histórico · Perfil.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const items = [
    GavNavItem(Icons.home_outlined, 'Inicio'),
    GavNavItem(Icons.bar_chart_rounded, 'Predicción'),
    GavNavItem(Icons.history, 'Histórico'),
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
