import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/ui/gav_widgets.dart';

/// Barra inferior del cliente: Inicio · Viajes · Asistente · Perfil.
class ClienteShell extends StatelessWidget {
  const ClienteShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const items = [
    GavNavItem(Icons.home_outlined, 'Inicio'),
    GavNavItem(Icons.route_outlined, 'Viajes'),
    GavNavItem(Icons.chat_bubble_outline, 'Asistente'),
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
