import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../data/cliente_repository.dart';

class _Mensaje {
  const _Mensaje(this.texto, {required this.mio, this.lugares = const [], this.error = false});
  final String texto;
  final bool mio;
  final bool error;
  final List<LugarPopular> lugares;
}

/// Cliente · Asistente GAV (chatbot del backend con Gemini).
class AsistentePage extends ConsumerStatefulWidget {
  const AsistentePage({super.key});

  @override
  ConsumerState<AsistentePage> createState() => _AsistentePageState();
}

class _AsistentePageState extends ConsumerState<AsistentePage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _mensajes = <_Mensaje>[
    const _Mensaje(
      '¡Hola! Soy el asistente de GAV. Pregúntame qué visitar en Cartagena o a dónde ir, '
      'y te sugiero destinos para tu próximo viaje.',
      mio: false,
    ),
  ];
  bool _esperando = false;

  static const _sugerencias = [
    '¿Qué playas me recomiendas?',
    'Lugares históricos para visitar',
    '¿Dónde puedo comer?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar([String? texto]) async {
    final t = (texto ?? _input.text).trim();
    if (t.isEmpty || _esperando) return;
    _input.clear();
    setState(() {
      _mensajes.add(_Mensaje(t, mio: true));
      _esperando = true;
    });
    _bajar();
    try {
      final r = await ref.read(clienteRepositoryProvider).preguntar(t);
      setState(() => _mensajes.add(_Mensaje(r.texto, mio: false, lugares: r.lugares)));
    } catch (e) {
      setState(() => _mensajes.add(_Mensaje(userMessageOf(e), mio: false, error: true)));
    } finally {
      if (mounted) setState(() => _esperando = false);
      _bajar();
    }
  }

  void _bajar() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    return Scaffold(
      backgroundColor: g.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GavTopBar(
                eyebrow: 'GAV · Cliente',
                title: 'Asistente',
                subtitle: 'Recomendaciones de destinos en Cartagena',
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final m in _mensajes) _Burbuja(m),
                  if (_esperando)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Escribiendo…', style: GavText.muted(context, size: 12)),
                      ),
                    ),
                  if (_mensajes.length == 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _sugerencias)
                          ActionChip(
                            label: Text(s, style: GavText.body(context, size: 12)),
                            backgroundColor: g.surface,
                            side: BorderSide(color: g.border),
                            onPressed: () => _enviar(s),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: g.border))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      style: GavText.body(context),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      decoration: const InputDecoration(hintText: 'Escribe tu pregunta…', counterText: ''),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GavIconButton(icon: Icons.send_rounded, gold: true, onTap: _esperando ? null : _enviar),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja(this.m);
  final _Mensaje m;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    return Align(
      alignment: m.mio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        decoration: BoxDecoration(
          color: m.mio ? g.goldContainer : g.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(m.mio ? 14 : 4),
            bottomRight: Radius.circular(m.mio ? 4 : 14),
          ),
          border: Border.all(color: m.error ? g.danger : g.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.texto, style: GavText.body(context, size: 13.5, color: m.error ? g.danger : g.text)),
            if (m.lugares.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final l in m.lugares.take(5))
                    GestureDetector(
                      onTap: () => context.push('/cliente/solicitar', extra: l.nombre),
                      child: GavChip(l.nombre, kind: GavChipKind.gold, upper: false),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Toca un lugar para pedir un viaje', style: GavText.body(context, size: 10.5, color: g.textFaint)),
            ],
          ],
        ),
      ),
    );
  }
}
