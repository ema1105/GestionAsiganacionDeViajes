import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../domain/auth_repository.dart';
import '../controllers/sesion_controller.dart';

enum _Modo { login, registro }

/// Mockups 01 Login y 02 Registro (misma pantalla con selector).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  _Modo _modo = _Modo.login;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final oscuro = ref.watch(themeControllerProvider) == ThemeMode.dark;
    final esLogin = _modo == _Modo.login;

    return Scaffold(
      backgroundColor: g.background,
      body: Stack(
        children: [
          // Círculos decorativos de la esquina superior derecha.
          Positioned(
            top: -60,
            right: -70,
            child: CustomPaint(size: const Size(240, 240), painter: _CirculosPainter(g.gold)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: g.gold.withValues(alpha: 0.7)),
                          ),
                          child: Icon(
                            esLogin ? Icons.near_me_outlined : Icons.chevron_left,
                            size: 17,
                            color: g.gold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GAV', style: GavText.title(context, size: 17)),
                              Text(
                                'GESTIÓN DE ASIGNACIÓN DE VIAJES',
                                style: GavText.label(context).copyWith(fontSize: 8.5),
                              ),
                            ],
                          ),
                        ),
                        GavIconButton(
                          icon: oscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          tooltip: oscuro ? 'Tema claro' : 'Tema oscuro',
                          onTap: () => ref.read(themeControllerProvider.notifier).alternar(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Text('PLATAFORMA GAV', style: GavText.eyebrow(context)),
                    const SizedBox(height: 10),
                    _TituloConAcento(
                      antes: esLogin ? 'Gestión de ' : 'Crea tu ',
                      acento: esLogin ? 'viajes' : 'cuenta',
                      despues: esLogin ? ' con precisión' : '',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      esLogin
                          ? 'Consulta cuántas solicitudes de viaje se esperan por mes y compáralas con el mismo mes del año anterior.'
                          : 'Regístrate como huésped para solicitar y seguir tus viajes.',
                      style: GavText.muted(context, size: 13),
                    ),
                    const SizedBox(height: 26),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GavSegmented<_Modo>(
                        options: const {_Modo.login: 'Iniciar sesión', _Modo.registro: 'Registrarse'},
                        selected: _modo,
                        onChanged: (m) => setState(() => _modo = m),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: esLogin ? const _LoginForm() : const _RegistroForm(),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Tecnológico Comfenalco · Proyecto de aula VIII semestre',
                      textAlign: TextAlign.center,
                      style: GavText.body(context, size: 10.5, color: g.textFaint),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloConAcento extends StatelessWidget {
  const _TituloConAcento({required this.antes, required this.acento, required this.despues});
  final String antes;
  final String acento;
  final String despues;

  @override
  Widget build(BuildContext context) {
    final base = GavText.title(context, size: 34);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: antes),
          TextSpan(
            text: acento,
            style: GavFonts.get(
              family: GavFonts.serif,
              fontSize: 34,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: context.gav.gold,
            ),
          ),
          TextSpan(text: despues),
        ],
      ),
    );
  }
}

class _CirculosPainter extends CustomPainter {
  _CirculosPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.35 - i * 0.1);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 60.0 + i * 38),
        math.pi * 0.35,
        math.pi * 1.3,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CirculosPainter oldDelegate) => oldDelegate.color != color;
}

// ───────────────────────── Login ─────────────────────────

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _form = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  final _focoUsuario = FocusNode();
  bool _enviando = false;
  bool _ocultar = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (ref.read(sesionControllerProvider.notifier).expiroPorTiempo) {
      _error = const UnauthorizedFailure().message;
    }
  }

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    _focoUsuario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref.read(sesionControllerProvider.notifier).login(_usuario.text, _contrasena.text);
    } catch (e) {
      setState(() => _error = userMessageOf(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    return Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GavTextField(
              label: 'Nombre de usuario',
              controller: _usuario,
              focusNode: _focoUsuario,
              hint: 'admin',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu usuario' : null,
            ),
            GavTextField(
              label: 'Contraseña',
              controller: _contrasena,
              hint: 'Tu contraseña',
              obscure: _ocultar,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _enviar(),
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
              suffix: IconButton(
                icon: Icon(
                  _ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: g.textFaint,
                ),
                onPressed: () => setState(() => _ocultar = !_ocultar),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: GavText.body(context, size: 12.5, color: g.danger)),
              ),
            const SizedBox(height: 6),
            GavPrimaryButton(label: 'Iniciar sesión', loading: _enviando, onPressed: _enviar),
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: () {
                  _usuario.clear();
                  _focoUsuario.requestFocus();
                },
                child: Text.rich(
                  TextSpan(
                    style: GavText.muted(context, size: 12),
                    children: [
                      const TextSpan(text: '¿Eres conductor? '),
                      TextSpan(
                        text: 'Entrar como conductor',
                        style: TextStyle(color: g.gold, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Registro ─────────────────────────

class _RegistroForm extends ConsumerStatefulWidget {
  const _RegistroForm();

  @override
  ConsumerState<_RegistroForm> createState() => _RegistroFormState();
}

class _RegistroFormState extends ConsumerState<_RegistroForm> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _usuario = TextEditingController();
  final _documento = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();
  DateTime? _nacimiento;
  bool _acepta = false;
  bool _enviando = false;
  String? _error;
  Map<String, String> _erroresCampo = const {};

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _usuario, _documento, _correo, _telefono, _contrasena, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _requerido(String? v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null;

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _nacimiento ?? DateTime(hoy.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(hoy.year - 14, hoy.month, hoy.day),
      helpText: 'Fecha de nacimiento',
    );
    if (f != null) setState(() => _nacimiento = f);
  }

  Future<void> _enviar() async {
    if (_enviando || !(_form.currentState?.validate() ?? false)) return;
    if (_nacimiento == null) {
      setState(() => _error = 'Selecciona tu fecha de nacimiento.');
      return;
    }
    if (!_acepta) {
      setState(() => _error = 'Debes aceptar los términos y condiciones.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
      _erroresCampo = const {};
    });
    try {
      await ref.read(sesionControllerProvider.notifier).registrar(
            RegistroCliente(
              nombreCompleto: _nombre.text,
              apellidosCompletos: _apellido.text,
              nombreUsuario: _usuario.text,
              numeroDocumento: _documento.text,
              email: _correo.text,
              telefono: _telefono.text,
              contrasena: _contrasena.text,
              fechaNacimiento: _nacimiento!,
            ),
          );
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
    final n = _nacimiento;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GavTextField(
                  label: 'Nombre',
                  controller: _nombre,
                  hint: 'María',
                  errorText: _erroresCampo['nombreCompleto'],
                  validator: _requerido,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GavTextField(
                  label: 'Apellido',
                  controller: _apellido,
                  hint: 'Gómez',
                  errorText: _erroresCampo['apellidosCompletos'],
                  validator: _requerido,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GavTextField(
                  label: 'Usuario',
                  controller: _usuario,
                  hint: 'mariagomez',
                  errorText: _erroresCampo['nombreUsuario'],
                  validator: (v) => (v == null || v.trim().length < 4) ? 'Mínimo 4 caracteres' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GavTextField(
                  label: 'Documento (CC)',
                  controller: _documento,
                  hint: '1000000001',
                  keyboardType: TextInputType.number,
                  errorText: _erroresCampo['numeroDocumento'],
                  validator: _requerido,
                ),
              ),
            ],
          ),
          GavTextField(
            label: 'Correo electrónico',
            controller: _correo,
            hint: 'maria@correo.com',
            keyboardType: TextInputType.emailAddress,
            errorText: _erroresCampo['email'],
            validator: (v) => (v == null || !v.contains('@')) ? 'Correo no válido' : null,
          ),
          GavTextField(
            label: 'Teléfono',
            controller: _telefono,
            hint: '300 000 0000',
            keyboardType: TextInputType.phone,
            errorText: _erroresCampo['telefono'],
            validator: _requerido,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FECHA DE NACIMIENTO', style: GavText.label(context)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _elegirFecha,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: g.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: g.border),
                    ),
                    child: Text(
                      n == null
                          ? 'Selecciona una fecha'
                          : '${n.day.toString().padLeft(2, '0')}/${n.month.toString().padLeft(2, '0')}/${n.year}',
                      style: GavText.body(context, color: n == null ? g.textFaint : g.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GavTextField(
            label: 'Contraseña',
            controller: _contrasena,
            hint: 'Mínimo 6 caracteres',
            obscure: true,
            errorText: _erroresCampo['contrasena'],
            validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          GavTextField(
            label: 'Confirmar contraseña',
            controller: _confirmar,
            hint: 'Repite tu contraseña',
            obscure: true,
            validator: (v) => v != _contrasena.text ? 'Las contraseñas no coinciden' : null,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(value: _acepta, onChanged: (v) => setState(() => _acepta = v ?? false)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: GavText.muted(context, size: 12),
                    children: [
                      const TextSpan(text: 'Acepto los '),
                      TextSpan(text: 'términos y condiciones', style: TextStyle(color: g.gold)),
                      const TextSpan(text: ' y el tratamiento de mis datos personales.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: GavText.body(context, size: 12.5, color: g.danger)),
            ),
          const SizedBox(height: 18),
          GavPrimaryButton(label: 'Crear cuenta', loading: _enviando, onPressed: _enviar),
        ],
      ),
    );
  }
}
