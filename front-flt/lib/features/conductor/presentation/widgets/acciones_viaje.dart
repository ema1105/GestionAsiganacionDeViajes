import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/lugares/ruta_viaje.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../viajes_cliente/domain/entities/viaje.dart';
import '../../data/conductor_repository_impl.dart';
import '../../domain/solicitud_pendiente.dart';
import '../controllers/conductor_providers.dart';

/// Ejecuta la siguiente transición del viaje (en camino → iniciar → finalizar).
/// Compartido por el Panel y la pestaña "Viaje". Al finalizar abre la
/// calificación del cliente. Devuelve true si la acción se aplicó.
Future<bool> ejecutarAccionConductor(
  BuildContext context,
  WidgetRef ref,
  AccionConductor accion,
  Viaje viaje,
) async {
  if (accion == AccionConductor.finalizar) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Finalizar viaje?'),
        content: Text('Confirma que llegaste al destino de ${viaje.clienteNombre ?? 'tu cliente'}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Finalizar')),
        ],
      ),
    );
    if (ok != true) return false;
  }

  try {
    await ref.read(conductorRepositoryProvider).ejecutar(accion, viaje.id);
  } catch (e) {
    if (context.mounted) showErrorSnack(context, e);
    return false;
  }

  // Al finalizar, la tarjeta del viaje desaparece en el siguiente frame: la hoja de
  // calificación se abre ANTES de invalidar, así queda montada en el Navigator.
  if (accion == AccionConductor.finalizar && context.mounted) {
    unawaited(mostrarCalificarCliente(context, viaje));
  }
  ref.invalidate(viajeActivoConductorProvider);
  if (accion == AccionConductor.finalizar) {
    ref
      ..invalidate(resumenGananciasProvider)
      ..invalidate(historialConductorProvider);
  }
  return true;
}

/// Hoja "Calificar cliente" (POST /api/conductor/viajes/{id}/calificar-cliente).
Future<void> mostrarCalificarCliente(BuildContext context, Viaje viaje) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CalificarClienteSheet(viaje: viaje),
    );

class _CalificarClienteSheet extends ConsumerStatefulWidget {
  const _CalificarClienteSheet({required this.viaje});
  final Viaje viaje;

  @override
  ConsumerState<_CalificarClienteSheet> createState() => _CalificarClienteSheetState();
}

class _CalificarClienteSheetState extends ConsumerState<_CalificarClienteSheet> {
  int _puntos = 5;
  final _comentario = TextEditingController();
  final _etiquetas = <String>{};
  bool _enviando = false;
  String? _error;

  static const _opciones = ['Puntual', 'Amable', 'Respetuoso', 'Buena comunicación'];

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    final texto = [
      if (_etiquetas.isNotEmpty) _etiquetas.join(', '),
      if (_comentario.text.trim().isNotEmpty) _comentario.text.trim(),
    ].join('. ');
    try {
      await ref
          .read(conductorRepositoryProvider)
          .calificarCliente(widget.viaje.id, puntuacion: _puntos, comentario: texto);
      if (!mounted) return;
      Navigator.of(context).pop();
      showInfoSnack(context, 'Calificaste a ${widget.viaje.clienteNombre ?? 'tu cliente'}. ¡Gracias!');
    } catch (e) {
      setState(() => _error = userMessageOf(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Califica a tu cliente', style: GavText.title(context, size: 22)),
          const SizedBox(height: 4),
          Text(
            '${widget.viaje.clienteNombre ?? 'Cliente'} · ${widget.viaje.ruta}',
            style: GavText.muted(context, size: 12.5),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                iconSize: 36,
                onPressed: () => setState(() => _puntos = i + 1),
                icon: Icon(i < _puntos ? Icons.star_rounded : Icons.star_border_rounded, color: g.gold),
              );
            }),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final o in _opciones)
                FilterChip(
                  label: Text(o),
                  selected: _etiquetas.contains(o),
                  onSelected: (s) => setState(() => s ? _etiquetas.add(o) : _etiquetas.remove(o)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GavTextField(label: 'Comentario (opcional)', controller: _comentario, hint: '¿Cómo fue el viaje?'),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!, style: GavText.body(context, size: 12.5, color: g.danger)),
            ),
          GavPrimaryButton(label: 'Enviar calificación', loading: _enviando, onPressed: _enviar),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _enviando ? null : () => Navigator.of(context).pop(),
            child: const Text('Omitir por ahora (puedes calificar desde el Historial)'),
          ),
        ],
      ),
    );
  }
}
