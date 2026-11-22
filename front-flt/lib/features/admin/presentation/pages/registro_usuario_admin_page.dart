import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/auth_repository.dart' show RegistroCliente;
import '../../data/admin_repository.dart';
import '../admin_providers.dart';

/// Valores de `Usuario.TipoDocumento` en el backend.
const _tiposDocumento = {
  'CC': 'CC',
  'CE': 'CE',
  'TI': 'TI',
  'PASAPORTE': 'Pasaporte',
  'PERMISO_PERMANECIA': 'PPT',
};

/// Valores de `Conductor.TipoLicencia` en el backend.
const _tiposLicencia = ['A1', 'A2', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'];

/// Admin · Registrar un conductor con su vehículo.
/// POST /api/admin/conductores crea usuario + vehículo + conductor en una sola transacción.
/// Los clientes se registran solos desde la app (no desde el panel admin).
class RegistroUsuarioAdminPage extends ConsumerStatefulWidget {
  const RegistroUsuarioAdminPage({super.key});

  @override
  ConsumerState<RegistroUsuarioAdminPage> createState() => _RegistroUsuarioAdminPageState();
}

class _RegistroUsuarioAdminPageState extends ConsumerState<RegistroUsuarioAdminPage> {
  final _form = GlobalKey<FormState>();

  // Datos personales y de acceso
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _documento = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();
  String _tipoDocumento = 'CC';
  DateTime? _nacimiento;

  // Conductor
  final _licencia = TextEditingController();
  String _tipoLicencia = 'B1';

  // Vehículo
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _placa = TextEditingController();
  final _capacidad = TextEditingController(text: '4');
  int? _categoriaId;

  bool _enviando = false;
  String? _error;
  Map<String, String> _erroresCampo = const {};

  @override
  void dispose() {
    for (final c in [
      _nombre, _apellido, _documento, _correo, _telefono, _usuario, _contrasena, _confirmar,
      _licencia, _marca, _modelo, _placa, _capacidad,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _requerido(String? v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null;

  static const _edadMinima = 18;

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final limite = DateTime(hoy.year - _edadMinima, hoy.month, hoy.day);
    final inicial = _nacimiento ?? DateTime(hoy.year - 30);
    final f = await showDatePicker(
      context: context,
      initialDate: inicial.isAfter(limite) ? limite : inicial,
      firstDate: DateTime(1920),
      lastDate: limite,
      helpText: 'Fecha de nacimiento',
    );
    if (f != null) setState(() => _nacimiento = f);
  }

  RegistroCliente _datosUsuario() => RegistroCliente(
        nombreCompleto: _nombre.text,
        apellidosCompletos: _apellido.text,
        nombreUsuario: _usuario.text,
        numeroDocumento: _documento.text,
        tipoDocumento: _tipoDocumento,
        email: _correo.text,
        telefono: _telefono.text,
        contrasena: _contrasena.text,
        fechaNacimiento: _nacimiento!,
      );

  Future<void> _guardar() async {
    if (_enviando) return;
    final formOk = _form.currentState?.validate() ?? false;
    String? falta;
    if (_nacimiento == null) {
      falta = 'Selecciona la fecha de nacimiento.';
    } else if (_categoriaId == null) {
      falta = 'Selecciona la categoría del vehículo.';
    }
    if (!formOk || falta != null) {
      setState(() => _error = falta ?? 'Revisa los campos marcados.');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
      _erroresCampo = const {};
    });
    final repo = ref.read(adminRepositoryProvider);
    try {
      final c = await repo.registrarConductor(
        NuevoConductor(
          usuario: _datosUsuario(),
          licencia: _licencia.text,
          tipoLicencia: _tipoLicencia,
          marcaVehiculo: _marca.text,
          modeloVehiculo: _modelo.text,
          placaVehiculo: _placa.text,
          capacidadMaxima: int.parse(_capacidad.text.trim()),
          categoriaVehiculoId: _categoriaId!,
        ),
      );
      ref
        ..invalidate(conductoresAdminProvider)
        ..invalidate(vehiculosAdminProvider);
      if (!mounted) return;
      showInfoSnack(context, 'Conductor ${c.nombre.isEmpty ? _nombre.text.trim() : c.nombre} registrado.');
      context.pop(true);
    } on ValidationFailure catch (f) {
      setState(() {
        _erroresCampo = f.fieldErrors;
        _error = f.message;
      });
    } catch (e) {
      setState(() => _error = userMessageOf(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    return GavPage(
      children: [
        GavTopBar(
          eyebrow: 'GAV · Admin',
          title: 'Nuevo conductor',
          subtitle: 'Crea la cuenta del conductor y registra su vehículo',
          onBack: () => context.pop(),
        ),
        const SizedBox(height: 4),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Seccion(
                titulo: 'Datos personales',
                icono: Icons.badge_outlined,
                children: [
                  _Par(
                    GavTextField(
                      label: 'Nombres',
                      controller: _nombre,
                      hint: 'Carlos',
                      errorText: _erroresCampo['nombreCompleto'],
                      validator: _requerido,
                    ),
                    GavTextField(
                      label: 'Apellidos',
                      controller: _apellido,
                      hint: 'Pérez Gómez',
                      errorText: _erroresCampo['apellidosCompletos'],
                      validator: _requerido,
                    ),
                  ),
                  const _Etiqueta('Tipo de documento'),
                  GavFilterChips<String>(
                    options: _tiposDocumento,
                    selected: _tipoDocumento,
                    onChanged: (v) => setState(() => _tipoDocumento = v),
                  ),
                  const SizedBox(height: 14),
                  _Par(
                    GavTextField(
                      label: 'Número de documento',
                      controller: _documento,
                      hint: '1047000000',
                      keyboardType: TextInputType.number,
                      errorText: _erroresCampo['numeroDocumento'],
                      validator: _requerido,
                    ),
                    _CampoFecha(fecha: _nacimiento, onTap: _elegirFecha),
                  ),
                  _Par(
                    GavTextField(
                      label: 'Correo electrónico',
                      controller: _correo,
                      hint: 'carlos@correo.com',
                      keyboardType: TextInputType.emailAddress,
                      errorText: _erroresCampo['email'],
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Correo no válido';
                      },
                    ),
                    GavTextField(
                      label: 'Teléfono',
                      controller: _telefono,
                      hint: '3001234567',
                      keyboardType: TextInputType.phone,
                      errorText: _erroresCampo['telefono'],
                      validator: (v) {
                        final t = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                        return t.length < 7 ? 'Teléfono no válido' : null;
                      },
                    ),
                  ),
                ],
              ),
              _Seccion(
                titulo: 'Acceso a la app',
                icono: Icons.lock_outline,
                children: [
                  GavTextField(
                    label: 'Usuario',
                    controller: _usuario,
                    hint: 'carlosperez',
                    errorText: _erroresCampo['nombreUsuario'],
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.length < 4 || t.length > 50) return 'Entre 4 y 50 caracteres';
                      if (t.contains(' ')) return 'Sin espacios';
                      return null;
                    },
                  ),
                  _Par(
                    GavTextField(
                      label: 'Contraseña',
                      controller: _contrasena,
                      hint: 'Mínimo 6 caracteres',
                      obscure: true,
                      errorText: _erroresCampo['contrasena'],
                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    GavTextField(
                      label: 'Confirmar',
                      controller: _confirmar,
                      hint: 'Repite la contraseña',
                      obscure: true,
                      validator: (v) => v != _contrasena.text ? 'No coinciden' : null,
                    ),
                  ),
                ],
              ),
              _Seccion(
                titulo: 'Licencia de conducción',
                icono: Icons.credit_card_outlined,
                children: [
                  GavTextField(
                    label: 'Número de licencia',
                    controller: _licencia,
                    hint: 'LIC-1047000000',
                    errorText: _erroresCampo['licencia'],
                    validator: _requerido,
                  ),
                  const _Etiqueta('Categoría de licencia'),
                  GavFilterChips<String>(
                    options: {for (final t in _tiposLicencia) t: t},
                    selected: _tipoLicencia,
                    onChanged: (v) => setState(() => _tipoLicencia = v),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
              _Seccion(
                titulo: 'Vehículo',
                icono: Icons.directions_car_filled_outlined,
                children: [
                  _Par(
                    GavTextField(
                      label: 'Marca',
                      controller: _marca,
                      hint: 'Chevrolet',
                      errorText: _erroresCampo['marcaVehiculo'],
                      validator: _requerido,
                    ),
                    GavTextField(
                      label: 'Modelo',
                      controller: _modelo,
                      hint: 'Onix 2022',
                      errorText: _erroresCampo['modeloVehiculo'],
                      validator: _requerido,
                    ),
                  ),
                  _Par(
                    GavTextField(
                      label: 'Placa',
                      controller: _placa,
                      hint: 'ABC123',
                      errorText: _erroresCampo['placaVehiculo'],
                      validator: (v) {
                        final t = v?.replaceAll(RegExp(r'[\s-]'), '') ?? '';
                        return RegExp(r'^[A-Za-z0-9]{5,7}$').hasMatch(t) ? null : 'Placa no válida';
                      },
                    ),
                    GavTextField(
                      label: 'Capacidad (pasajeros)',
                      controller: _capacidad,
                      hint: '4',
                      keyboardType: TextInputType.number,
                      errorText: _erroresCampo['capacidadMaxima'],
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        return (n == null || n < 1 || n > 20) ? 'Entre 1 y 20' : null;
                      },
                    ),
                  ),
                  const _Etiqueta('Categoría del vehículo'),
                  _SelectorCategoria(
                    seleccion: _categoriaId,
                    error: _erroresCampo['categoriaVehiculoId'],
                    onChanged: (id) => setState(() => _categoriaId = id),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: GavText.body(context, size: 12.5, color: g.danger)),
          ),
        GavPrimaryButton(
          label: 'Registrar conductor',
          loading: _enviando,
          onPressed: _guardar,
        ),
      ],
    );
  }
}

/// Tarjeta con título e ícono que agrupa campos del formulario.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.icono, required this.children});
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    return GavCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: g.gold),
              const SizedBox(width: 8),
              Text(titulo, style: GavText.strong(context, size: 14.5)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// Dos campos lado a lado en pantallas anchas; uno debajo del otro en el celular.
class _Par extends StatelessWidget {
  const _Par(this.a, this.b);
  final Widget a;
  final Widget b;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => c.maxWidth < 420
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, b])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)],
              ),
      );
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto.toUpperCase(), style: GavText.label(context)),
      );
}

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({required this.fecha, required this.onTap});
  final DateTime? fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final f = fecha;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FECHA DE NACIMIENTO', style: GavText.label(context)),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: g.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: g.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      f == null
                          ? 'Selecciona una fecha'
                          : '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}',
                      style: GavText.body(context, color: f == null ? g.textFaint : g.text),
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, size: 16, color: g.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Categorías reales del backend (GET /api/admin/categorias).
class _SelectorCategoria extends ConsumerWidget {
  const _SelectorCategoria({required this.seleccion, required this.onChanged, this.error});
  final int? seleccion;
  final ValueChanged<int> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = context.gav;
    return ref.watch(categoriasVehiculoProvider).when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Row(
            children: [
              Expanded(
                child: Text(
                  'No se pudieron cargar las categorías: ${userMessageOf(e)}',
                  style: GavText.body(context, size: 12, color: g.danger),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(categoriasVehiculoProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
          data: (lista) {
            if (lista.isEmpty) {
              return Text(
                'No hay categorías registradas en el sistema.',
                style: GavText.body(context, size: 12, color: g.danger),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GavFilterChips<int?>(
                  options: {for (final c in lista) c.id: _titulo(c.nombre)},
                  selected: seleccion,
                  onChanged: (id) {
                    if (id != null) onChanged(id);
                  },
                ),
                if (_descripcion(lista) case final d?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(d, style: GavText.muted(context, size: 11.5)),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(error!, style: GavText.body(context, size: 12, color: g.danger)),
                  ),
              ],
            );
          },
        );
  }

  String? _descripcion(List<CategoriaVehiculo> lista) {
    for (final c in lista) {
      if (c.id == seleccion) return c.descripcion;
    }
    return null;
  }

  static String _titulo(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
