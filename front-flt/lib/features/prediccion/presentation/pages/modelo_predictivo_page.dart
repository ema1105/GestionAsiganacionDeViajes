import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/prediccion_repository_impl.dart';
import '../../domain/entrenamiento.dart';
import 'prediccion_page.dart';

/// Admin · Modelo predictivo: reentrenar la RNA desde la app (sin tocar el backend).
///
/// POST /api/prediccion/reentrenar inicia el entrenamiento en segundo plano y la
/// pantalla consulta /reentrenar/estado cada 3 s hasta que termina. El servicio
/// sigue respondiendo con el modelo anterior mientras tanto.
class ModeloPredictivoPage extends ConsumerStatefulWidget {
  const ModeloPredictivoPage({super.key});

  @override
  ConsumerState<ModeloPredictivoPage> createState() => _ModeloPredictivoPageState();
}

class _ModeloPredictivoPageState extends ConsumerState<ModeloPredictivoPage> {
  EstadoEntrenamiento? _estado;
  Object? _error;
  bool _cargando = true;
  bool _enviando = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _consultar() async {
    try {
      final e = await ref.read(prediccionRepositoryProvider).estadoReentrenamiento();
      if (!mounted) return;
      final terminoAhora = _estado?.entrenando == true && !e.entrenando;
      setState(() {
        _estado = e;
        _error = null;
        _cargando = false;
      });
      if (e.entrenando) {
        _timer ??= Timer.periodic(const Duration(seconds: 3), (_) => _consultar());
      } else {
        _timer?.cancel();
        _timer = null;
      }
      // El modelo nuevo cambia la ficha y las predicciones: refrescar la pestaña Predicción.
      if (terminoAhora) PrediccionPage.refrescar(ref);
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err;
        _cargando = false;
      });
    }
  }

  Future<void> _reentrenar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Reentrenar el modelo?'),
        content: const Text(
          'Se entrenará la red neuronal con todos los viajes finalizados y cancelados de la base de datos. '
          'Tarda unos minutos. Mientras tanto las predicciones siguen usando el modelo actual, '
          'y si algo falla se conserva el modelo anterior.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reentrenar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _enviando = true);
    try {
      final e = await ref.read(prediccionRepositoryProvider).reentrenar();
      if (!mounted) return;
      setState(() => _estado = e);
      _timer ??= Timer.periodic(const Duration(seconds: 3), (_) => _consultar());
    } catch (err) {
      if (mounted) showErrorSnack(context, err);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _restaurar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Volver al modelo anterior?'),
        content: const Text('Se descartará el modelo recién entrenado y se usará el que había antes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _enviando = true);
    try {
      final e = await ref.read(prediccionRepositoryProvider).restaurarModeloAnterior();
      if (!mounted) return;
      setState(() => _estado = e);
      PrediccionPage.refrescar(ref);
      showInfoSnack(context, 'Se restauró el modelo anterior.');
    } catch (err) {
      if (mounted) showErrorSnack(context, err);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _estado;
    return GavPage(
      onRefresh: _consultar,
      children: [
        GavTopBar(
          eyebrow: 'GAV · Admin',
          title: 'Modelo predictivo',
          subtitle: 'Reentrena la red neuronal con los datos actuales',
          onBack: () => context.pop(),
        ),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_error != null && e == null)
          GavCard(
            child: Column(
              children: [
                Text(userMessageOf(_error!), textAlign: TextAlign.center, style: GavText.muted(context)),
                const SizedBox(height: 6),
                Text(
                  'Verifica que el prediction-service esté corriendo con la versión nueva de app.py.',
                  textAlign: TextAlign.center,
                  style: GavText.muted(context, size: 11.5),
                ),
                const SizedBox(height: 12),
                GavButton(label: 'Reintentar', onPressed: _consultar),
              ],
            ),
          )
        else if (e != null) ...[
          _ModeloActualCard(m: e.actuales),
          _EstadoCard(estado: e),
          if (e.fase == FaseEntrenamiento.completado && e.anteriores != null && e.nuevas != null)
            _ComparacionCard(antes: e.anteriores!, despues: e.nuevas!),
          const SizedBox(height: 6),
          GavButton(
            label: e.entrenando ? 'Entrenando…' : 'Reentrenar modelo',
            icon: Icons.model_training,
            kind: GavButtonKind.gold,
            expand: true,
            height: 50,
            onPressed: e.entrenando || _enviando ? null : _reentrenar,
          ),
          if (e.hayRespaldo && !e.entrenando) ...[
            const SizedBox(height: 10),
            GavButton(
              label: 'Restaurar modelo anterior',
              icon: Icons.history,
              kind: GavButtonKind.goldOutline,
              expand: true,
              onPressed: _enviando ? null : _restaurar,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Datos usados: viajes FINALIZADOS y CANCELADOS, agrupados por mes. '
            'El mes en curso se excluye porque está incompleto. '
            'MAE y RMSE salen del backtest: entre más bajos, mejor.',
            style: GavText.muted(context, size: 11.5),
          ),
        ],
      ],
    );
  }
}

String _num(double? v, {int dec = 1}) => v == null ? '—' : v.toStringAsFixed(dec).replaceAll('.', ',');

class _ModeloActualCard extends StatelessWidget {
  const _ModeloActualCard({required this.m});
  final MetricasModelo? m;

  @override
  Widget build(BuildContext context) {
    final x = m;
    return GavCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MODELO EN USO', style: GavText.label(context)),
          const SizedBox(height: 8),
          if (x == null)
            Text('Todavía no hay un modelo entrenado.', style: GavText.muted(context))
          else ...[
            Text(
              'Entrenado ${x.entrenadoEn == null ? '—' : '${Fmt.fechaCorta(x.entrenadoEn)}, ${Fmt.hora(x.entrenadoEn)}'}',
              style: GavText.strong(context, size: 14),
            ),
            const SizedBox(height: 2),
            Text(
              'Último mes con datos: ${x.ultimoMesReal ?? '—'} · ${x.muestras ?? '—'} muestras',
              style: GavText.muted(context, size: 12),
            ),
            const SizedBox(height: 12),
            GavKpiGrid(
              children: [
                GavKpiCard(label: 'MAE', value: _num(x.mae)),
                GavKpiCard(label: 'RMSE', value: _num(x.rmse)),
                GavKpiCard(label: 'MAPE', value: x.mape == null ? '—' : '${_num(x.mape)} %'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EstadoCard extends StatelessWidget {
  const _EstadoCard({required this.estado});
  final EstadoEntrenamiento estado;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final (titulo, icono, color) = switch (estado.fase) {
      FaseEntrenamiento.entrenando => ('Entrenando…', Icons.sync, g.gold),
      FaseEntrenamiento.completado => ('Entrenamiento completado', Icons.check_circle_outline, g.success),
      FaseEntrenamiento.error => ('El entrenamiento falló', Icons.error_outline, g.danger),
      FaseEntrenamiento.inactivo => ('Sin entrenamientos en esta sesión', Icons.schedule, g.textMuted),
    };
    return GavCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(titulo, style: GavText.strong(context, size: 14.5))),
            ],
          ),
          if (estado.entrenando) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 10),
            Text(estado.paso ?? 'Iniciando…', style: GavText.muted(context, size: 12)),
            Text(
              'Iniciado ${Fmt.hora(estado.iniciadoEn)} · suele tardar 2–5 minutos.',
              style: GavText.muted(context, size: 11),
            ),
          ] else if (estado.mensaje != null) ...[
            const SizedBox(height: 8),
            Text(estado.mensaje!, style: GavText.muted(context, size: 12)),
          ],
          if (estado.log.isNotEmpty && !estado.entrenando)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Ver detalle del proceso', style: GavText.muted(context, size: 12)),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      estado.log.join('\n'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComparacionCard extends StatelessWidget {
  const _ComparacionCard({required this.antes, required this.despues});
  final MetricasModelo antes;
  final MetricasModelo despues;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final a = antes.rmse, d = despues.rmse;
    final mejora = a != null && d != null && d <= a;
    return GavCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANTES VS AHORA', style: GavText.label(context)),
          const SizedBox(height: 10),
          _fila(context, 'MAE', antes.mae, despues.mae),
          _fila(context, 'RMSE', antes.rmse, despues.rmse),
          _fila(context, 'MAPE %', antes.mape, despues.mape),
          const SizedBox(height: 8),
          Text(
            mejora
                ? 'El modelo nuevo tiene menor error. Se recomienda conservarlo.'
                : 'El modelo nuevo tiene mayor error. Puedes restaurar el anterior.',
            style: GavText.body(context, size: 12.5, color: mejora ? g.success : g.danger),
          ),
        ],
      ),
    );
  }

  Widget _fila(BuildContext context, String nombre, double? a, double? d) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(nombre, style: GavText.muted(context, size: 12.5))),
            Text('${_num(a)}  →  ', style: GavText.muted(context, size: 12.5)),
            Text(_num(d), style: GavText.strong(context, size: 13)),
          ],
        ),
      );
}
