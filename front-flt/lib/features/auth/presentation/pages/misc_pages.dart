import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/sesion_controller.dart';

/// Se muestra mientras se lee la sesión guardada al abrir la app.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// Admin y recepcionista siguen en el panel web por ahora.
class RolNoSoportadoPage extends ConsumerWidget {
  const RolNoSoportadoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionControllerProvider).value;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.desktop_windows_outlined, size: 56),
              const SizedBox(height: 12),
              Text(
                'El rol ${sesion?.rol.etiqueta ?? ''} se gestiona desde el panel web de GAV.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.read(sesionControllerProvider.notifier).logout(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
