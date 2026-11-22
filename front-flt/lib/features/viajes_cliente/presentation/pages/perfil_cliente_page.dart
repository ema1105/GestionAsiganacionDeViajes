import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/ui/perfil_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/controllers/sesion_controller.dart';
import '../../../conductor/presentation/pages/resenas_page.dart';
import '../../data/cliente_repository.dart';

/// Cliente · Mi perfil (mismo diseño que el perfil de admin y conductor).
class PerfilClientePage extends ConsumerWidget {
  const PerfilClientePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(perfilClienteProvider);
    final resumen = ref.watch(resumenClienteProvider).value;
    final p = async.value;

    return GavPage(
      onRefresh: () async {
        ref
          ..invalidate(perfilClienteProvider)
          ..invalidate(resumenClienteProvider);
        await ref.read(perfilClienteProvider.future);
      },
      children: [
        GavTopBar(
          eyebrow: 'GAV · Cliente',
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
                      await ref.read(clienteRepositoryProvider).actualizarPerfil(email: email, telefono: tel);
                      ref.invalidate(perfilClienteProvider);
                    },
                  ),
                ),
        ),
        AsyncValueView<PerfilCliente>(
          value: async,
          onRetry: () => ref.invalidate(perfilClienteProvider),
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PerfilHeaderCard(nombre: p.nombreCompleto, rol: 'Cliente'),
              GavCard(
                child: GavInfoGrid(
                  items: [
                    GavInfo('Nombre', p.nombre),
                    GavInfo('Apellido', p.apellidos),
                    GavInfo('Usuario', p.usuario),
                    GavInfo('Documento', p.documento ?? ''),
                    GavInfo('Correo electrónico', p.email, full: true),
                    GavInfo('Teléfono', p.telefono, full: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (resumen != null)
          GavCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mi calificación', style: GavText.strong(context, size: 14.5)),
                      const SizedBox(height: 4),
                      Text(
                        '${resumen.promedio.total} calificaci${resumen.promedio.total == 1 ? 'ón' : 'ones'} de conductores',
                        style: GavText.muted(context, size: 12),
                      ),
                    ],
                  ),
                ),
                Estrellas(valor: resumen.promedio.promedio ?? 0),
              ],
            ),
          ),
        GavCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preferencias', style: GavText.strong(context, size: 14.5)),
              const SizedBox(height: 4),
              const PreferenciaTema(),
            ],
          ),
        ),
        CerrarSesionButton(onPressed: () => ref.read(sesionControllerProvider.notifier).logout()),
      ],
    );
  }
}
