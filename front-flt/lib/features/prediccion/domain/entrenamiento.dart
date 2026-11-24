import '../../../core/json/json_read.dart';

/// Fase del reentrenamiento del modelo (`GET /api/prediccion/reentrenar/estado`).
enum FaseEntrenamiento {
  inactivo,
  entrenando,
  completado,
  error;

  static FaseEntrenamiento desde(String? v) =>
      values.firstWhere((f) => f.name == v, orElse: () => inactivo);
}

/// Métricas de una versión del modelo (backtest).
class MetricasModelo {
  const MetricasModelo({this.mae, this.rmse, this.mape, this.entrenadoEn, this.ultimoMesReal, this.muestras});

  static MetricasModelo? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    return MetricasModelo(
      mae: asDouble(j['mae']),
      rmse: asDouble(j['rmse']),
      mape: asDouble(j['mape']),
      entrenadoEn: DateTime.tryParse(asString(j['entrenado_en']) ?? '')?.toLocal(),
      ultimoMesReal: asString(j['ultimo_mes_real']),
      muestras: asInt(j['muestras_entrenamiento']),
    );
  }

  final double? mae;
  final double? rmse;
  final double? mape;
  final DateTime? entrenadoEn;
  final String? ultimoMesReal;
  final int? muestras;
}

/// Estado del último reentrenamiento lanzado desde la app.
class EstadoEntrenamiento {
  const EstadoEntrenamiento({
    required this.fase,
    this.paso,
    this.mensaje,
    this.iniciadoEn,
    this.finalizadoEn,
    this.log = const [],
    this.anteriores,
    this.nuevas,
    this.actuales,
    this.hayRespaldo = false,
  });

  factory EstadoEntrenamiento.fromJson(Map<String, dynamic> j) => EstadoEntrenamiento(
        fase: FaseEntrenamiento.desde(asString(j['estado'])),
        paso: asString(j['paso']),
        mensaje: asString(j['mensaje']),
        iniciadoEn: DateTime.tryParse(asString(j['iniciado_en']) ?? '')?.toLocal(),
        finalizadoEn: DateTime.tryParse(asString(j['finalizado_en']) ?? '')?.toLocal(),
        log: (j['log'] as List<dynamic>? ?? const []).map((e) => '$e').toList(),
        anteriores: MetricasModelo.fromJson(j['metricas_anteriores']),
        nuevas: MetricasModelo.fromJson(j['metricas_nuevas']),
        actuales: MetricasModelo.fromJson(j['metricas_actuales']),
        hayRespaldo: j['hay_respaldo'] == true,
      );

  final FaseEntrenamiento fase;
  final String? paso;
  final String? mensaje;
  final DateTime? iniciadoEn;
  final DateTime? finalizadoEn;
  final List<String> log;
  final MetricasModelo? anteriores;
  final MetricasModelo? nuevas;
  final MetricasModelo? actuales;
  final bool hayRespaldo;

  bool get entrenando => fase == FaseEntrenamiento.entrenando;
}
