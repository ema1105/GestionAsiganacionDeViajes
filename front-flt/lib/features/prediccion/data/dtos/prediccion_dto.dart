import '../../../../core/json/json_read.dart';
import '../../domain/periodo.dart';
import '../../domain/prediccion.dart';

/// DTOs espejo del JSON de FastAPI (`src/pronostico.py`).

Periodo _periodo(Object? v, String campo) =>
    Periodo.tryParse(asString(v)) ?? (throw FormatException('Periodo inválido en $campo: $v'));

Map<String, dynamic> _obj(Object? v, String campo) =>
    v is Map<String, dynamic> ? v : (throw FormatException('Objeto requerido: $campo'));

/// `generado_en` y `entrenado_en` traen zona (`+00:00`): no se aplica SERVER_OFFSET_HOURS.
DateTime? _fecha(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

class IntervaloDto {
  const IntervaloDto(this.min, this.max);

  factory IntervaloDto.fromJson(Map<String, dynamic> j) =>
      IntervaloDto(reqInt(j['min'], 'intervalo.min'), reqInt(j['max'], 'intervalo.max'));

  static IntervaloDto? tryFromJson(Object? v) => v is Map<String, dynamic> ? IntervaloDto.fromJson(v) : null;

  final int min;
  final int max;

  IntervaloSolicitudes toEntity() => IntervaloSolicitudes(min, max);
}

class ModeloDto {
  const ModeloDto({required this.nombre, required this.version, required this.mae, required this.rmse});

  factory ModeloDto.fromJson(Map<String, dynamic> j) => ModeloDto(
        nombre: asString(j['nombre']) ?? 'RNA',
        version: asString(j['version']) ?? '',
        mae: reqDouble(j['mae'], 'modelo.mae'),
        rmse: reqDouble(j['rmse'], 'modelo.rmse'),
      );

  final String nombre;
  final String version;
  final double mae;
  final double rmse;

  ModeloResumen toEntity() => ModeloResumen(nombre: nombre, version: version, mae: mae, rmse: rmse);
}

class PeriodoObjetivoDto {
  const PeriodoObjetivoDto({
    required this.desde,
    required this.hasta,
    required this.etiqueta,
    required this.solicitudesPredichas,
    required this.intervalo,
  });

  factory PeriodoObjetivoDto.fromJson(Map<String, dynamic> j) => PeriodoObjetivoDto(
        desde: _periodo(j['desde'], 'periodo_objetivo.desde'),
        hasta: _periodo(j['hasta'], 'periodo_objetivo.hasta'),
        etiqueta: asString(j['etiqueta']) ?? '',
        solicitudesPredichas: reqInt(j['solicitudes_predichas'], 'solicitudes_predichas'),
        intervalo: IntervaloDto.fromJson(_obj(j['intervalo'], 'periodo_objetivo.intervalo')),
      );

  final Periodo desde;
  final Periodo hasta;
  final String etiqueta;
  final int solicitudesPredichas;
  final IntervaloDto intervalo;

  PeriodoObjetivo toEntity() => PeriodoObjetivo(
        desde: desde,
        hasta: hasta,
        etiqueta: etiqueta,
        predichas: solicitudesPredichas,
        intervalo: intervalo.toEntity(),
      );
}

class PeriodoBaseDto {
  const PeriodoBaseDto({
    required this.desde,
    required this.hasta,
    required this.etiqueta,
    required this.solicitudesReales,
  });

  factory PeriodoBaseDto.fromJson(Map<String, dynamic> j) => PeriodoBaseDto(
        desde: _periodo(j['desde'], 'periodo_base.desde'),
        hasta: _periodo(j['hasta'], 'periodo_base.hasta'),
        etiqueta: asString(j['etiqueta']) ?? '',
        solicitudesReales: reqInt(j['solicitudes_reales'], 'solicitudes_reales'),
      );

  final Periodo desde;
  final Periodo hasta;
  final String etiqueta;
  final int solicitudesReales;

  PeriodoBase toEntity() =>
      PeriodoBase(desde: desde, hasta: hasta, etiqueta: etiqueta, reales: solicitudesReales);
}

class ComparacionDto {
  const ComparacionDto({
    required this.variacionAbsoluta,
    required this.variacionPorcentual,
    required this.tendencia,
  });

  factory ComparacionDto.fromJson(Map<String, dynamic> j) => ComparacionDto(
        variacionAbsoluta: reqInt(j['variacion_absoluta'], 'variacion_absoluta'),
        variacionPorcentual: asDouble(j['variacion_porcentual']),
        tendencia: asString(j['tendencia']),
      );

  final int variacionAbsoluta;
  final double? variacionPorcentual;
  final String? tendencia;

  Comparacion toEntity() => Comparacion(
        variacionAbsoluta: variacionAbsoluta,
        variacionPorcentual: variacionPorcentual,
        tendencia: Tendencia.fromApi(tendencia),
      );
}

class MesPrediccionDto {
  const MesPrediccionDto({
    required this.periodo,
    required this.etiqueta,
    required this.solicitudesPredichas,
    required this.solicitudesRealesBase,
    required this.enPeriodo,
    this.intervalo,
  });

  factory MesPrediccionDto.fromJson(Map<String, dynamic> j) => MesPrediccionDto(
        periodo: _periodo(j['periodo'], 'otros_meses.periodo'),
        etiqueta: asString(j['etiqueta']) ?? '',
        solicitudesPredichas: asInt(j['solicitudes_predichas']),
        solicitudesRealesBase: asInt(j['solicitudes_reales_base']),
        enPeriodo: asBool(j['en_periodo']),
        intervalo: IntervaloDto.tryFromJson(j['intervalo']),
      );

  final Periodo periodo;
  final String etiqueta;
  final int? solicitudesPredichas;
  final int? solicitudesRealesBase;
  final bool enPeriodo;
  final IntervaloDto? intervalo;

  MesPrediccion toEntity() => MesPrediccion(
        periodo: periodo,
        etiqueta: etiqueta,
        predichas: solicitudesPredichas,
        realesBase: solicitudesRealesBase,
        enPeriodo: enPeriodo,
        intervalo: intervalo?.toEntity(),
      );
}

class PrediccionDto {
  const PrediccionDto({
    required this.generadoEn,
    required this.modelo,
    required this.periodoObjetivo,
    required this.periodoBase,
    required this.comparacion,
    required this.otrosMeses,
  });

  factory PrediccionDto.fromJson(Map<String, dynamic> j) => PrediccionDto(
        generadoEn: _fecha(j['generado_en']),
        modelo: ModeloDto.fromJson(_obj(j['modelo'], 'modelo')),
        periodoObjetivo: PeriodoObjetivoDto.fromJson(_obj(j['periodo_objetivo'], 'periodo_objetivo')),
        periodoBase: PeriodoBaseDto.fromJson(_obj(j['periodo_base'], 'periodo_base')),
        comparacion: ComparacionDto.fromJson(_obj(j['comparacion'], 'comparacion')),
        otrosMeses: (j['otros_meses'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(MesPrediccionDto.fromJson)
            .toList(),
      );

  final DateTime? generadoEn;
  final ModeloDto modelo;
  final PeriodoObjetivoDto periodoObjetivo;
  final PeriodoBaseDto periodoBase;
  final ComparacionDto comparacion;
  final List<MesPrediccionDto> otrosMeses;

  Prediccion toEntity() => Prediccion(
        generadoEn: generadoEn,
        modelo: modelo.toEntity(),
        objetivo: periodoObjetivo.toEntity(),
        base: periodoBase.toEntity(),
        comparacion: comparacion.toEntity(),
        meses: otrosMeses.map((m) => m.toEntity()).toList(),
      );
}

/// `GET /api/prediccion/modelo` (metadata.json + horizonte_disponible_hasta).
class FichaModeloDto {
  const FichaModeloDto(this.json);

  final Map<String, dynamic> json;

  FichaModelo toEntity() {
    final metricas = json['metricas'] is Map<String, dynamic>
        ? json['metricas'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return FichaModelo(
      nombre: asString(json['nombre']) ?? 'RNA',
      version: asString(json['version']) ?? '',
      entrenadoEn: _fecha(json['entrenado_en']),
      origenSerie: _periodo(json['origen_serie'], 'origen_serie'),
      ultimoMesReal: _periodo(json['ultimo_mes_real'], 'ultimo_mes_real'),
      horizonteHasta: _periodo(json['horizonte_disponible_hasta'], 'horizonte_disponible_hasta'),
      mae: reqDouble(metricas['mae'], 'metricas.mae'),
      rmse: reqDouble(metricas['rmse'], 'metricas.rmse'),
      mape: asDouble(metricas['mape']),
    );
  }
}
