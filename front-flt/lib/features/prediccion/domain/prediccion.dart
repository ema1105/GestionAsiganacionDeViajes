import 'periodo.dart';

/// Tendencia que calcula el servicio (|variación| < 2 % → estable).
enum Tendencia {
  incremento,
  disminucion,
  estable,

  /// El periodo base sumó 0 solicitudes: no hay variación porcentual.
  sinBase;

  static Tendencia fromApi(String? v) => switch (v?.toLowerCase()) {
        'incremento' => incremento,
        'disminucion' || 'disminución' => disminucion,
        'estable' => estable,
        _ => sinBase,
      };
}

class ModeloResumen {
  const ModeloResumen({
    required this.nombre,
    required this.version,
    required this.mae,
    required this.rmse,
  });

  final String nombre;
  final String version;
  final double mae;
  final double rmse;
}

class IntervaloSolicitudes {
  const IntervaloSolicitudes(this.min, this.max);
  final int min;
  final int max;
}

class PeriodoObjetivo {
  const PeriodoObjetivo({
    required this.desde,
    required this.hasta,
    required this.etiqueta,
    required this.predichas,
    required this.intervalo,
  });

  final Periodo desde;
  final Periodo hasta;

  /// "oct 2027" o "sep 2027 – oct 2027".
  final String etiqueta;
  final int predichas;
  final IntervaloSolicitudes intervalo;

  List<Periodo> get meses => rangoPeriodos(desde, hasta);
  int get dias => meses.fold(0, (a, p) => a + p.dias);
  bool get esUnMes => desde == hasta;
}

class PeriodoBase {
  const PeriodoBase({
    required this.desde,
    required this.hasta,
    required this.etiqueta,
    required this.reales,
  });

  final Periodo desde;
  final Periodo hasta;
  final String etiqueta;
  final int reales;

  int get dias => rangoPeriodos(desde, hasta).fold(0, (a, p) => a + p.dias);
}

class Comparacion {
  const Comparacion({
    required this.variacionAbsoluta,
    required this.variacionPorcentual,
    required this.tendencia,
  });

  final int variacionAbsoluta;

  /// null cuando la tendencia es [Tendencia.sinBase].
  final double? variacionPorcentual;
  final Tendencia tendencia;
}

/// Un mes de `otros_meses` (serie de 12 meses para listas y gráficas).
class MesPrediccion {
  const MesPrediccion({
    required this.periodo,
    required this.etiqueta,
    required this.predichas,
    required this.realesBase,
    required this.enPeriodo,
    this.intervalo,
  });

  final Periodo periodo;
  final String etiqueta;

  /// null si el mes está fuera del horizonte del modelo.
  final int? predichas;

  /// Mismo mes en el año base. null si aún no existe como dato real.
  final int? realesBase;
  final bool enPeriodo;

  /// Rango ~90 % del mes. null en versiones del servicio que no lo envían.
  final IntervaloSolicitudes? intervalo;

  bool get tienePrediccion => predichas != null;
}

/// Respuesta completa de `GET /api/prediccion/mensual`.
class Prediccion {
  const Prediccion({
    required this.generadoEn,
    required this.modelo,
    required this.objetivo,
    required this.base,
    required this.comparacion,
    required this.meses,
  });

  /// Momento de la consulta (no del entrenamiento: ver [FichaModelo.entrenadoEn]).
  final DateTime? generadoEn;
  final ModeloResumen modelo;
  final PeriodoObjetivo objetivo;
  final PeriodoBase base;
  final Comparacion comparacion;
  final List<MesPrediccion> meses;
}

/// `GET /api/prediccion/modelo`: ficha técnica y límites de consulta.
class FichaModelo {
  const FichaModelo({
    required this.nombre,
    required this.version,
    required this.entrenadoEn,
    required this.origenSerie,
    required this.ultimoMesReal,
    required this.horizonteHasta,
    required this.mae,
    required this.rmse,
    this.mape,
  });

  final String nombre;
  final String version;
  final DateTime? entrenadoEn;
  final Periodo origenSerie;
  final Periodo ultimoMesReal;
  final Periodo horizonteHasta;
  final double mae;
  final double rmse;
  final double? mape;

  /// Primer mes que el modelo pronostica (el siguiente al último dato real).
  Periodo get primerPronostico => ultimoMesReal.siguiente;

  /// Cada predicción necesita 26 meses de historia previa (README del servicio).
  Periodo get primerConsultable => origenSerie.sumarMeses(26);

  bool admite(Periodo p) => !(p < primerConsultable) && !(p > horizonteHasta);
}

enum EstadoServicio { ok, sinModelo }
