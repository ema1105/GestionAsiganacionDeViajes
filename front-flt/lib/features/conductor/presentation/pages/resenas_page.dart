import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../controllers/conductor_providers.dart';

/// Mockup conductor 06 · Mis calificaciones.
class ResenasPage extends ConsumerWidget {
  const ResenasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(resenasProvider);
    return GavPage(
      onRefresh: () => ref.refresh(resenasProvider.future),
      children: [
        const GavTopBar(
          eyebrow: 'GAV · Conductor',
          title: 'Mis calificaciones',
          subtitle: 'Valoraciones recibidas de tus clientes',
        ),
        AsyncValueView<ResumenResenas>(
          value: async,
          onRetry: () => ref.invalidate(resenasProvider),
          data: (r) {
            final prom = r.promedio.promedio;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GavCard(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        prom == null ? '—' : prom.toStringAsFixed(1).replaceAll('.', ','),
                        style: GavText.title(context, size: 44),
                      ),
                      const SizedBox(height: 6),
                      Estrellas(valor: prom ?? 0, size: 18),
                      const SizedBox(height: 6),
                      Text(
                        '${r.promedio.total} calificaci${r.promedio.total == 1 ? 'ón' : 'ones'}',
                        style: GavText.muted(context, size: 12),
                      ),
                    ],
                  ),
                ),
                if (r.resenas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: EmptyView(mensaje: 'Aún no tienes reseñas', icono: Icons.star_border_rounded),
                  ),
                for (final c in r.resenas)
                  GavCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(c.autor, style: GavText.strong(context, size: 13.5))),
                            Icon(Icons.star_rounded, size: 15, color: context.gav.gold),
                            const SizedBox(width: 3),
                            Text('${c.puntuacion},0', style: GavText.strong(context, size: 12.5)),
                          ],
                        ),
                        if ((c.comentario ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('"${c.comentario}"', style: GavText.muted(context, size: 12.5)),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class Estrellas extends StatelessWidget {
  const Estrellas({super.key, required this.valor, this.size = 16});
  final double valor;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final icon = valor >= i + 1
              ? Icons.star_rounded
              : (valor > i ? Icons.star_half_rounded : Icons.star_border_rounded);
          return Icon(icon, size: size, color: context.gav.gold);
        }),
      );
}
