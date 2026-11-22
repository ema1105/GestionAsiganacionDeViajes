import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/lugares/ruta_viaje.dart';
import '../../../../core/pagination/pagina.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/cliente_repository.dart';
import '../../data/viajes_cliente_repository_impl.dart';
import '../../domain/entities/estado_viaje.dart';
import '../../domain/entities/viaje.dart';
import '../widgets/viaje_widgets.dart';

const _tamano = 4;

class _Consulta {
  const _Consulta(this.estado, this.page);
  final EstadoViaje? estado;
  final int page;

  @override
  bool operator ==(Object other) => other is _Consulta && other.estado == estado && other.page == page;

  @override
  int get hashCode => Object.hash(estado, page);
}

final _viajesProvider = FutureProvider.autoDispose.family<Pagina<Viaje>, _Consulta>(
  (ref, q) => ref
      .watch(viajesClienteRepositoryProvider)
      .historial(FiltroViajes(estado: q.estado), page: q.page, size: _tamano),
);

/// Cliente · Mis viajes (historial con filtros, paginado y calificación).
class ViajesClientePage extends ConsumerStatefulWidget {
  const ViajesClientePage({super.key});

  @override
  ConsumerState<ViajesClientePage> createState() => _ViajesClientePageState();
}

class _ViajesClientePageState extends ConsumerState<ViajesClientePage> {
  EstadoViaje? _estado;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final q = _Consulta(_estado, _page);
    final async = ref.watch(_viajesProvider(q));

    return GavPage(
      onRefresh: () async {
        ref.invalidate(_viajesProvider(q));
        await ref.read(_viajesProvider(q).future);
      },
      children: [
        const GavTopBar(
          eyebrow: 'GAV · Cliente',
          title: 'Mis viajes',
          subtitle: 'Historial de tus viajes en la plataforma',
        ),
        GavFilterChips<EstadoViaje?>(
          options: const {
            null: 'Todos',
            EstadoViaje.finalizado: 'Finalizados',
            EstadoViaje.cancelado: 'Cancelados',
          },
          selected: _estado,
          onChanged: (e) => setState(() {
            _estado = e;
            _page = 0;
          }),
        ),
        const SizedBox(height: 14),
        AsyncValueView<Pagina<Viaje>>(
          value: async,
          onRetry: () => ref.invalidate(_viajesProvider(q)),
          isEmpty: (p) => p.items.isEmpty,
          empty: const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyView(mensaje: 'Aún no tienes viajes con este filtro', icono: Icons.route_outlined),
          ),
          data: (p) {
            final paginas = (p.totalElements / _tamano).ceil();
            return Column(
              children: [
                for (final v in p.items) _ViajeCard(viaje: v),
                GavPaginationFooter(
                  text: 'Mostrando ${p.items.length} de ${p.totalElements} viajes · '
                      'página ${p.page + 1} de ${paginas == 0 ? 1 : paginas}',
                  onPrev: p.page > 0 ? () => setState(() => _page--) : null,
                  onNext: p.isLast ? null : () => setState(() => _page++),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ViajeCard extends StatelessWidget {
  const _ViajeCard({required this.viaje});
  final Viaje viaje;

  @override
  Widget build(BuildContext context) {
    final v = viaje;
    return GavCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(v.ruta, style: GavText.strong(context, size: 14))),
              Text(Fmt.pesos(v.precio), style: GavText.strong(context, size: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${Fmt.fechaCorta(v.solicitadoEn)} · '
            '${v.tieneConductor ? v.conductorNombre : 'Sin conductor'}',
            style: GavText.muted(context, size: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              EstadoViajeChip(v.estado),
              const Spacer(),
              if (v.estado == EstadoViaje.finalizado && v.tieneConductor)
                GestureDetector(
                  onTap: () => mostrarCalificar(context, v),
                  child: Row(
                    children: [
                      Icon(Icons.star_border_rounded, size: 16, color: context.gav.gold),
                      const SizedBox(width: 4),
                      Text('Calificar', style: GavText.strong(context, size: 12.5).copyWith(color: context.gav.gold)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hoja "Calificar conductor" (POST /api/cliente/viajes/{id}/calificar).
Future<void> mostrarCalificar(BuildContext context, Viaje viaje) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CalificarSheet(viaje: viaje),
    );

class _CalificarSheet extends ConsumerStatefulWidget {
  const _CalificarSheet({required this.viaje});
  final Viaje viaje;

  @override
  ConsumerState<_CalificarSheet> createState() => _CalificarSheetState();
}

class _CalificarSheetState extends ConsumerState<_CalificarSheet> {
  int _puntos = 5;
  final _comentario = TextEditingController();
  bool _enviando = false;
  String? _error;

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
    try {
      await ref
          .read(clienteRepositoryProvider)
          .calificar(widget.viaje.id, puntuacion: _puntos, comentario: _comentario.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showInfoSnack(context, '¡Gracias por calificar a ${widget.viaje.conductorNombre}!');
    } catch (e) {
      setState(() => _error = userMessageOf(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Califica tu viaje', style: GavText.title(context, size: 22)),
            const SizedBox(height: 4),
            Text(
              '${widget.viaje.ruta} · ${widget.viaje.conductorNombre}',
              style: GavText.muted(context, size: 12.5),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  iconSize: 36,
                  onPressed: () => setState(() => _puntos = i + 1),
                  icon: Icon(
                    i < _puntos ? Icons.star_rounded : Icons.star_border_rounded,
                    color: context.gav.gold,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            GavTextField(label: 'Comentario (opcional)', controller: _comentario, hint: '¿Cómo fue tu viaje?'),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!, style: GavText.body(context, size: 12.5, color: context.gav.danger)),
              ),
            GavPrimaryButton(label: 'Enviar calificación', loading: _enviando, onPressed: _enviar),
          ],
        ),
      );
}
