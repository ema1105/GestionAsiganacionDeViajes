import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/ui/perfil_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/controllers/sesion_controller.dart';
import '../../data/admin_repository.dart';
import '../admin_providers.dart';

/// Mockup admin 11 · Mi perfil.
class PerfilAdminPage extends ConsumerStatefulWidget {
  const PerfilAdminPage({super.key});

  @override
  ConsumerState<PerfilAdminPage> createState() => _PerfilAdminPageState();
}

class _PerfilAdminPageState extends ConsumerState<PerfilAdminPage> {
  // Preferencias del mockup (solo locales; el backend no las persiste aún).
  bool _notifPrediccion = true;
  bool _alertasCorreo = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(perfilAdminProvider);
    final p = async.value;

    return GavPage(
      onRefresh: () => ref.refresh(perfilAdminProvider.future),
      children: [
        GavTopBar(
          title: 'Mi perfil',
          subtitle: 'Gestiona tu información personal',
          trailing: p == null
              ? null
              : GavButton(
                  label: 'Editar perfil',
                  kind: GavButtonKind.goldOutline,
                  height: 38,
                  onPressed: () => mostrarEditarPerfil(
                    context,
                    email: p.email,
                    telefono: p.telefono,
                    onGuardar: (email, tel) async {
                      await ref.read(adminRepositoryProvider).actualizarPerfil(email: email, telefono: tel);
                      ref.invalidate(perfilAdminProvider);
                    },
                  ),
                ),
        ),
        AsyncValueView<PerfilUsuario>(
          value: async,
          onRetry: () => ref.invalidate(perfilAdminProvider),
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PerfilHeaderCard(nombre: p.nombreCompleto, rol: 'Administrador'),
              GavCard(
                child: GavInfoGrid(
                  items: [
                    GavInfo('Nombre', p.nombre),
                    GavInfo('Apellido', p.apellidos),
                    GavInfo('Correo electrónico', p.email, full: true),
                    GavInfo('Teléfono', p.telefono, full: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        GavCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preferencias', style: GavText.strong(context, size: 14.5)),
              const SizedBox(height: 4),
              GavToggleRow(
                label: 'Notificaciones de predicción',
                value: _notifPrediccion,
                onChanged: (v) => setState(() => _notifPrediccion = v),
              ),
              const Divider(),
              GavToggleRow(
                label: 'Alertas por correo',
                value: _alertasCorreo,
                onChanged: (v) => setState(() => _alertasCorreo = v),
              ),
              const Divider(),
              const PreferenciaTema(),
            ],
          ),
        ),
        CerrarSesionButton(onPressed: () => ref.read(sesionControllerProvider.notifier).logout()),
      ],
    );
  }
}
