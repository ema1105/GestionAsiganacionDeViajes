import 'dart:math' as math;

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
}

/// Contenedor blanco redondeado donde se dibujan las gráficas.
class LienzoGrafica extends StatelessWidget {
  const LienzoGrafica({super.key, required this.height, required this.painter});
  final double height;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
        decoration: BoxDecoration(
          color: ColoresGrafica.fondo,
          borderRadius: BorderRadius.circular(10),
        ),
        child: CustomPaint(size: Size.infinite, painter: painter),
      );
}

void _texto(
  Canvas canvas,
  String texto,
  Offset centroArriba, {
  double size = 11,
  Color color = ColoresGrafica.tinta,
  bool bold = false,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(fontSize: size, color: color, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(centroArriba.dx - tp.width / 2, centroArriba.dy));
}

/// Mockup 04: barra real del año base contra barra predicha con su rango probable.
class BarrasComparacionPainter extends CustomPainter {
  BarrasComparacionPainter({
    required this.real,
    required this.prediccion,
    required this.minimo,
    required this.maximo,
    required this.etiquetaReal,
    required this.etiquetaPrediccion,
  });

  final int? real;
  final int prediccion;
  final int minimo;
  final int maximo;
  final String etiquetaReal;
  final String etiquetaPrediccion;

  @override
  void paint(Canvas canvas, Size size) {
    const zonaEtiquetas = 22.0;
    const zonaValor = 22.0;
    final base = size.height - zonaEtiquetas;
    final tope = math.max(1, [real ?? 0, prediccion, maximo].reduce(math.max)).toDouble();
    double y(num v) => base - (v / tope) * (base - zonaValor);

    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = ColoresGrafica.eje
        ..strokeWidth = 1,
    );

    final ancho = size.width * 0.234;
    final cxReal = size.width * 0.292;
    final cxPred = size.width * 0.708;

    void barra(double cx, num valor, Color color) => canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(cx - ancho / 2, y(valor), cx + ancho / 2, base),
            const Radius.circular(4),
          ),
          Paint()..color = color,
        );

    // Año base (real).
    if (real != null) {
      barra(cxReal, real!, ColoresGrafica.barraReal);
      _texto(canvas, '$real', Offset(cxReal, y(real!) - 19), size: 14, bold: true);
    } else {
      _texto(canvas, 'Sin dato', Offset(cxReal, base - 18), size: 11, color: ColoresGrafica.tintaSuave);
    }

    // Predicción + rango probable (barra de error).
    barra(cxPred, prediccion, ColoresGrafica.barraPrediccion);
    final rango = Paint()
      ..color = ColoresGrafica.tinta
      ..strokeWidth = 1.4;
    const brazo = 5.5;
    canvas
      ..drawLine(Offset(cxPred, y(maximo)), Offset(cxPred, y(minimo)), rango)
      ..drawLine(Offset(cxPred - brazo, y(maximo)), Offset(cxPred + brazo, y(maximo)), rango)
      ..drawLine(Offset(cxPred - brazo, y(minimo)), Offset(cxPred + brazo, y(minimo)), rango);
    _texto(canvas, '$prediccion', Offset(cxPred, y(maximo) - 19), size: 14, bold: true);

    _texto(canvas, etiquetaReal, Offset(cxReal, base + 5), color: ColoresGrafica.tintaSuave);
    _texto(canvas, etiquetaPrediccion, Offset(cxPred, base + 5), bold: true);
  }

  @override
  bool shouldRepaint(covariant BarrasComparacionPainter o) =>
      o.real != real || o.prediccion != prediccion || o.minimo != minimo || o.maximo != maximo ||
      o.etiquetaReal != etiquetaReal || o.etiquetaPrediccion != etiquetaPrediccion;
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
  bool operator ==(Object o) =>
      o is VelaMes && o.etiqueta == etiqueta && o.apertura == apertura && o.cierre == cierre &&
      o.minimo == minimo && o.maximo == maximo;

  @override
  int get hashCode => Object.hash(etiqueta, apertura, cierre, minimo, maximo);
}

class VelasPainter extends CustomPainter {
  VelasPainter(this.velas);
  final List<VelaMes> velas;

  @override
  void paint(Canvas canvas, Size size) {
    if (velas.isEmpty) return;
    const zonaEtiquetas = 16.0;
    final alto = size.height - zonaEtiquetas;

    // Escala ajustada al rango de los datos para que las diferencias se vean.
    final valores = [
      for (final v in velas) ...[v.minimo, v.maximo, ?v.apertura],
    ];
    final minV = valores.reduce(math.min).toDouble();
    final maxV = valores.reduce(math.max).toDouble();
    final margen = math.max(1.0, (maxV - minV) * 0.1);
    final piso = math.max(0.0, minV - margen);
    final techo = maxV + margen;
    double y(num v) => alto - ((v - piso) / (techo - piso)) * (alto - 6);

    canvas.drawLine(
      Offset(0, alto),
      Offset(size.width, alto),
      Paint()
        ..color = ColoresGrafica.eje
        ..strokeWidth = 1,
    );

    final paso = size.width / velas.length;
    final ancho = math.min(14.0, paso * 0.45);

    for (var i = 0; i < velas.length; i++) {
      final v = velas[i];
      final cx = paso * i + paso / 2;
      final color = v.sube ? ColoresGrafica.sube : ColoresGrafica.baja;

      canvas.drawLine(
        Offset(cx, y(v.maximo)),
        Offset(cx, y(v.minimo)),
        Paint()
          ..color = color
          ..strokeWidth = 1.2,
      );

      final apertura = v.apertura ?? v.cierre;
      final top = y(math.max(apertura, v.cierre));
      final bottom = y(math.min(apertura, v.cierre));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - ancho / 2, top, cx + ancho / 2, math.max(bottom, top + 3)),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );

      _texto(canvas, v.etiqueta, Offset(cx, alto + 3), size: 9, color: const Color(0xFF8A867F));
    }
  }

  @override
  bool shouldRepaint(covariant VelasPainter o) => !_mismas(o.velas, velas);

  static bool _mismas(List<VelaMes> a, List<VelaMes> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
