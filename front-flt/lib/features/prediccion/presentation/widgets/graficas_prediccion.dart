import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

/// Colores de las gráficas sobre fondo blanco (mockups 04 y 06).
abstract final class ColoresGrafica {
  static const fondo = Colors.white;
  static const eje = Color(0xFFD9D4C8);
  static const barraReal = Color(0xFFCBB998);
  static const barraPrediccion = Color(0xFFA98845);
  static const tinta = Color(0xFF12262B);
  static const tintaSuave = Color(0xFF5B6B70);
  static const sube = Color(0xFF34C46A);
  static const baja = Color(0xFFE5534B);
  static const etiquetaMes = Color(0xFF8A867F);
}

/// Contenedor blanco redondeado donde se dibujan las gráficas.
class LienzoGrafica extends StatelessWidget {
  const LienzoGrafica({super.key, required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
        decoration: BoxDecoration(
          color: ColoresGrafica.fondo,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      );
}

TextStyle _estilo({double size = 11, Color color = ColoresGrafica.tinta, bool bold = false}) =>
    TextStyle(fontSize: size, color: color, fontWeight: bold ? FontWeight.w700 : FontWeight.w400);

const _sinTitulos = AxisTitles(sideTitles: SideTitles(showTitles: false));
const _estiloTooltip = TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500);
const _animacion = Duration(milliseconds: 400);

/// Solo la línea base (eje X), sin marco ni cuadrícula.
FlBorderData _soloEjeX() => FlBorderData(
      show: true,
      border: const Border(bottom: BorderSide(color: ColoresGrafica.eje)),
    );

/// Mockup 04 (fl_chart · BarChart): barra real del año base contra barra predicha
/// con su rango probable dibujado como barra de error.
class GraficaBarrasComparacion extends StatelessWidget {
  const GraficaBarrasComparacion({
    super.key,
    required this.real,
    required this.prediccion,
    required this.minimo,
    required this.maximo,
    required this.etiquetaReal,
    required this.etiquetaPrediccion,
  });

  /// null si el año base no tiene dato real.
  final int? real;
  final int prediccion;
  final int minimo;
  final int maximo;
  final String etiquetaReal;
  final String etiquetaPrediccion;

  static const _zonaEtiquetas = 22.0;
  static const _zonaValor = 22.0;

  static final _pintorRango = FlSimpleErrorPainter(
    lineColor: ColoresGrafica.tinta,
    lineWidth: 1.4,
    capLength: 11,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final alto = c.maxHeight - _zonaEtiquetas;
          final tope = math.max(1, [real ?? 0, prediccion, maximo].reduce(math.max)).toDouble();
          // Igual que el diseño original: el valor más alto queda a _zonaValor del borde superior.
          final maxY = tope * alto / math.max(1.0, alto - _zonaValor);
          final pxPorUnidad = alto / maxY;
          final ancho = c.maxWidth * 0.234;
          final estiloValor = _estilo(size: 14, bold: true);

          BarChartRodData barra(num valor, Color color, BarChartRodLabel etiqueta, {FlErrorRange? rango}) =>
              BarChartRodData(
                toY: valor.toDouble(),
                toYErrorRange: rango,
                color: color,
                width: ancho,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                label: etiqueta,
              );

          final barraReal = real == null
              ? barra(
                  0,
                  Colors.transparent,
                  BarChartRodLabel(
                    show: true,
                    text: 'Sin dato',
                    style: _estilo(color: ColoresGrafica.tintaSuave),
                    offset: const Offset(0, 6),
                  ),
                )
              : barra(
                  real!,
                  ColoresGrafica.barraReal,
                  BarChartRodLabel(show: true, text: '$real', style: estiloValor, offset: const Offset(0, 2)),
                );

          // El valor predicho se escribe encima del rango probable, no encima de la barra.
          final sobreRango = math.max(0, maximo - prediccion) * pxPorUnidad;
          final barraPrediccion = barra(
            prediccion,
            ColoresGrafica.barraPrediccion,
            BarChartRodLabel(
              show: true,
              text: '$prediccion',
              style: estiloValor,
              offset: Offset(0, 2 + sobreRango),
            ),
            rango: FlErrorRange(
              lowerBy: math.max(0, prediccion - minimo).toDouble(),
              upperBy: math.max(0, maximo - prediccion).toDouble(),
            ),
          );

          return BarChart(
            duration: _animacion,
            BarChartData(
              minY: 0,
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              barGroups: [
                BarChartGroupData(x: 0, barRods: [barraReal]),
                BarChartGroupData(x: 1, barRods: [barraPrediccion]),
              ],
              errorIndicatorData: FlErrorIndicatorData<BarChartSpotErrorRangeCallbackInput>(
                painter: (_) => _pintorRango,
              ),
              gridData: const FlGridData(show: false),
              borderData: _soloEjeX(),
              titlesData: FlTitlesData(
                leftTitles: _sinTitulos,
                rightTitles: _sinTitulos,
                topTitles: _sinTitulos,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: _zonaEtiquetas,
                    getTitlesWidget: (value, meta) {
                      final esReal = value.round() == 0;
                      return SideTitleWidget(
                        meta: meta,
                        space: 5,
                        child: Text(
                          esReal ? etiquetaReal : etiquetaPrediccion,
                          style: esReal ? _estilo(color: ColoresGrafica.tintaSuave) : _estilo(bold: true),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => ColoresGrafica.tinta,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (group.x == 0) {
                      return real == null ? null : BarTooltipItem('Real: $real', _estiloTooltip);
                    }
                    return BarTooltipItem(
                      'Predicción: $prediccion\nRango probable: $minimo–$maximo',
                      _estiloTooltip,
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
}

/// Vela de un mes (mockup 06): apertura = real del año base, cierre = predicción,
/// mecha = rango probable del mes.
class VelaMes {
  const VelaMes({
    required this.etiqueta,
    required this.apertura,
    required this.cierre,
    required this.minimo,
    required this.maximo,
  });

  final String etiqueta;

  /// null si el año base no tiene dato real para ese mes.
  final int? apertura;
  final int cierre;
  final int minimo;
  final int maximo;

  bool get sube => apertura == null || cierre >= apertura!;

  @override
  bool operator ==(Object other) =>
      other is VelaMes && other.etiqueta == etiqueta && other.apertura == apertura && other.cierre == cierre &&
      other.minimo == minimo && other.maximo == maximo;

  @override
  int get hashCode => Object.hash(etiqueta, apertura, cierre, minimo, maximo);
}

/// Mockup 06 (fl_chart · CandlestickChart): una vela por mes del año.
class GraficaVelas extends StatelessWidget {
  const GraficaVelas(this.velas, {super.key});
  final List<VelaMes> velas;

  static const _zonaEtiquetas = 16.0;

  /// Grosor del borde del cuerpo: deja visible una rayita cuando apertura == cierre.
  static const _bordeCuerpo = 3.0;

  @override
  Widget build(BuildContext context) {
    if (velas.isEmpty) return const SizedBox.shrink();

    // Escala ajustada al rango de los datos para que las diferencias se vean.
    final valores = [
      for (final v in velas) ...[v.minimo, v.maximo, ?v.apertura],
    ];
    final minV = valores.reduce(math.min).toDouble();
    final maxV = valores.reduce(math.max).toDouble();
    final margen = math.max(1.0, (maxV - minV) * 0.1);
    final piso = math.max(0.0, minV - margen);
    final techo = maxV + margen;

    return LayoutBuilder(
      builder: (context, c) {
        final paso = c.maxWidth / velas.length;
        final ancho = math.min(14.0, paso * 0.45);

        final pintor = DefaultCandlestickPainter(
          candlestickStyleProvider: (spot, i) {
            final color = velas[i].sube ? ColoresGrafica.sube : ColoresGrafica.baja;
            return CandlestickStyle(
              lineColor: color,
              lineWidth: 1.2,
              bodyStrokeColor: color,
              bodyStrokeWidth: _bordeCuerpo,
              bodyFillColor: color,
              bodyWidth: math.max(1.0, ancho - _bordeCuerpo),
              bodyRadius: 2,
            );
          },
        );

        return CandlestickChart(
          duration: _animacion,
          CandlestickChartData(
            candlestickSpots: [
              for (var i = 0; i < velas.length; i++)
                CandlestickSpot(
                  x: i.toDouble(),
                  open: (velas[i].apertura ?? velas[i].cierre).toDouble(),
                  high: velas[i].maximo.toDouble(),
                  low: velas[i].minimo.toDouble(),
                  close: velas[i].cierre.toDouble(),
                ),
            ],
            candlestickPainter: pintor,
            minX: -0.5,
            maxX: velas.length - 0.5,
            minY: piso,
            maxY: techo,
            gridData: const FlGridData(show: false),
            borderData: _soloEjeX(),
            titlesData: FlTitlesData(
              leftTitles: _sinTitulos,
              rightTitles: _sinTitulos,
              topTitles: _sinTitulos,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: _zonaEtiquetas,
                  interval: 1,
                  minIncluded: false,
                  maxIncluded: false,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (value != i || i < 0 || i >= velas.length) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      space: 3,
                      child: Text(velas[i].etiqueta, style: _estilo(size: 9, color: ColoresGrafica.etiquetaMes)),
                    );
                  },
                ),
              ),
            ),
            candlestickTouchData: CandlestickTouchData(
              touchSpotThreshold: 12,
              touchTooltipData: CandlestickTouchTooltipData(
                getTooltipColor: (_) => ColoresGrafica.tinta,
                getTooltipItems: (painter, spot, i) {
                  final v = velas[i];
                  return CandlestickTooltipItem(
                    '${v.etiqueta}\n'
                    'Predicción: ${v.cierre}\n'
                    'Real año base: ${v.apertura ?? 'sin dato'}\n'
                    'Rango: ${v.minimo}–${v.maximo}',
                    textStyle: _estiloTooltip,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
