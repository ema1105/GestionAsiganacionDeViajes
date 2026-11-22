import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../error/app_failure.dart';
import '../theme/gav_colors.dart';
import '../theme/gav_theme.dart';

/// Pinta los 4 estados de una carga remota: cargando / error / vacío / datos.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.isEmpty,
    this.empty,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
        data: (d) => (isEmpty?.call(d) ?? false) ? (empty ?? const EmptyView()) : data(d),
        error: (e, _) => ErrorView(message: userMessageOf(e), onRetry: onRetry),
        loading: () => const LoadingView(),
      );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.mensaje = 'No hay información para mostrar', this.icono});

  final String mensaje;
  final IconData? icono;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono ?? Icons.inbox_outlined, size: 40, color: context.gav.textFaint),
              const SizedBox(height: 10),
              Text(mensaje, textAlign: TextAlign.center, style: GavText.muted(context, size: 13)),
            ],
          ),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: context.gav.danger),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: GavText.body(context, size: 13)),
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(foregroundColor: context.gav.gold),
                  child: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      );
}

/// SnackBar estándar para errores de acciones (botones, formularios).
void showErrorSnack(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(userMessageOf(error))));
}

void showInfoSnack(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje)));
}
