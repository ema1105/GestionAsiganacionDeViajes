import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/ui/perfil_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/controllers/sesion_controller.dart';
import '../../data/conductor_repository_impl.dart';
import '../../domain/conductor_models.dart';
import '../controllers/conductor_providers.dart';

/// Mockup conductor 07 · Mi perfil.
class PerfilConductorPage extends ConsumerWidget {
  const PerfilConductorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(perfilConductorProvider);
    final p = async.value;

    return GavPage(
      onRefresh: () => ref.refresh(perfilConductorProvider.future),
      children: [
        GavTopBar(
          eyebrow: 'GAV · Conductor',
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
                      await ref.read(conductorRepositoryProvider).actualizarPerfil(email: email, telefono: tel);
                      ref.invalidate(perfilConductorProvider);
                    },
                  ),
                ),
        ),
        AsyncValueView<PerfilConductor>(
          value: async,
          onRetry: () => ref.invalidate(perfilConductorProvider),
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PerfilHeaderCard(nombre: p.nombreCompleto, rol: 'Conductor'),
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
              GavCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vehículo asignado', style: GavText.strong(context, size: 14.5)),
                    const SizedBox(height: 12),
                    if (p.tieneVehiculo)
                      GavInfoGrid(
                        items: [
                          GavInfo('Marca y modelo', p.vehiculo),
                          GavInfo('Placa', p.placaVehiculo ?? ''),
                          GavInfo('Capacidad', '${p.capacidad} pasajeros'),
                          GavInfo('Categoría', p.categoriaVehiculo ?? ''),
                        ],
                      )
                    else
                      Text('Sin vehículo asignado.', style: GavText.muted(context)),
                    Text(
                      'Gestionado por administración · no editable',
                      style: GavText.body(context, size: 11, color: context.gav.textFaint),
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
                    const PreferenciaTema(),
                  ],
                ),
              ),
            ],
          ),
        ),
        CerrarSesionButton(onPressed: () => ref.read(sesionControllerProvider.notifier).logout()),
      ],
    );
  }
}
