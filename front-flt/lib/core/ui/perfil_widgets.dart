import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../error/app_failure.dart';
import '../theme/gav_colors.dart';
import '../theme/gav_theme.dart';
import '../theme/theme_controller.dart';
import 'gav_widgets.dart';

/// Toggle "Tema oscuro" (requisito: cambiar entre oscuro y claro).
class PreferenciaTema extends ConsumerWidget {
  const PreferenciaTema({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oscuro = ref.watch(themeControllerProvider) == ThemeMode.dark;
    return GavToggleRow(
      label: 'Tema oscuro',
      value: oscuro,
      onChanged: (v) => ref.read(themeControllerProvider.notifier).establecer(oscuro: v),
    );
  }
}

/// Card superior del perfil: avatar con iniciales, nombre y chip del rol.
class PerfilHeaderCard extends StatelessWidget {
  const PerfilHeaderCard({super.key, required this.nombre, required this.rol});
  final String nombre;
  final String rol;

  @override
  Widget build(BuildContext context) => GavCard(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              GavAvatar(nombre, size: 64),
              const SizedBox(height: 12),
              Text(nombre, style: GavText.strong(context, size: 16)),
              const SizedBox(height: 8),
              GavChip(rol, kind: GavChipKind.gold),
            ],
          ),
        ),
      );
}

/// Botón "Cerrar sesión" (borde, texto rojo).
class CerrarSesionButton extends StatelessWidget {
  const CerrarSesionButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: GavButton(
          label: 'Cerrar sesión',
          icon: Icons.logout,
          kind: GavButtonKind.dangerOutline,
          expand: true,
          height: 50,
          onPressed: onPressed,
        ),
      );
}

/// Hoja inferior "Editar perfil" (correo y teléfono, que es lo que el backend permite).
Future<void> mostrarEditarPerfil(
  BuildContext context, {
  required String email,
  required String telefono,
  required Future<void> Function(String email, String telefono) onGuardar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _EditarPerfilSheet(email: email, telefono: telefono, onGuardar: onGuardar),
  );
}

class _EditarPerfilSheet extends StatefulWidget {
  const _EditarPerfilSheet({required this.email, required this.telefono, required this.onGuardar});
  final String email;
  final String telefono;
  final Future<void> Function(String email, String telefono) onGuardar;

  @override
  State<_EditarPerfilSheet> createState() => _EditarPerfilSheetState();
}

class _EditarPerfilSheetState extends State<_EditarPerfilSheet> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  late final _telefono = TextEditingController(text: widget.telefono);
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.onGuardar(_email.text, _telefono.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = userMessageOf(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Editar perfil', style: GavText.title(context, size: 22)),
              const SizedBox(height: 18),
              GavTextField(
                label: 'Correo electrónico',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Correo no válido' : null,
              ),
              GavTextField(
                label: 'Teléfono',
                controller: _telefono,
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_error!, style: GavText.body(context, size: 12.5, color: context.gav.danger)),
                ),
              GavPrimaryButton(label: 'Guardar cambios', loading: _guardando, onPressed: _guardar),
            ],
          ),
        ),
      );
}
