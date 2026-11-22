import 'package:flutter_test/flutter_test.dart';
import 'package:gav_app/features/prediccion/data/dtos/prediccion_dto.dart';
import 'package:gav_app/features/prediccion/domain/periodo.dart';
import 'package:gav_app/features/prediccion/domain/prediccion.dart';

Map<String, dynamic> _respuesta({String tendencia = 'incremento', double? pct = 10.33}) => {
      'generado_en': '2026-11-09T21:37:31+00:00',
      'modelo': {'nombre': 'RNA-MLP demanda mensual GAV', 'version': '1.0.0', 'mae': 36.37, 'rmse': 45.2},
      'periodo_objetivo': {
        'desde': '2027-09',
        'hasta': '2027-10',
        'etiqueta': 'sep 2027 – oct 2027',
        'solicitudes_predichas': 844,
        'intervalo': {'min': 733, 'max': 954},
      },
      'periodo_base': {
        'desde': '2026-09',
        'hasta': '2026-10',
        'etiqueta': 'sep 2026 – oct 2026',
        'solicitudes_reales': 765,
      },
      'comparacion': {'variacion_absoluta': 79, 'variacion_porcentual': pct, 'tendencia': tendencia},
      'otros_meses': [
        {
          'periodo': '2027-10',
          'etiqueta': 'oct 2027',
          'solicitudes_predichas': 497,
          'intervalo': {'min': 460, 'max': 534},
          'solicitudes_reales_base': 450,
          'en_periodo': true,
        },
        {
          'periodo': '2027-11',
          'etiqueta': 'nov 2027',
          'solicitudes_predichas': null,
          'intervalo': null,
          'solicitudes_reales_base': null,
          'en_periodo': false,
        },
        // Servicio anterior: sin `intervalo`.
        {
          'periodo': '2027-01',
          'etiqueta': 'ene 2027',
          'solicitudes_predichas': 617,
          'solicitudes_reales_base': 558,
          'en_periodo': false,
        },
      ],
    };

void main() {
  group('PrediccionDto', () {
    test('mapea la respuesta de ejemplo del servicio', () {
      final p = PrediccionDto.fromJson(_respuesta()).toEntity();

      expect(p.objetivo.desde, const Periodo(2027, 9));
      expect(p.objetivo.hasta, const Periodo(2027, 10));
      expect(p.objetivo.predichas, 844);
      expect(p.objetivo.intervalo.min, 733);
      expect(p.objetivo.dias, 61); // sep (30) + oct (31)
      expect(p.base.reales, 765);
      expect(p.comparacion.tendencia, Tendencia.incremento);
      expect(p.comparacion.variacionPorcentual, closeTo(10.33, 0.001));
      expect(p.modelo.mae, closeTo(36.37, 0.001));
      expect(p.generadoEn!.isUtc, isFalse); // convertido a hora local
    });

    test('otros_meses tolera nulos y la ausencia de intervalo', () {
      final meses = PrediccionDto.fromJson(_respuesta()).toEntity().meses;

      expect(meses[0].intervalo!.max, 534);
      expect(meses[0].enPeriodo, isTrue);
      expect(meses[1].tienePrediccion, isFalse);
      expect(meses[1].realesBase, isNull);
      expect(meses[2].intervalo, isNull);
      expect(meses[2].predichas, 617);
    });

    test('tendencia sin_base deja la variación porcentual en null', () {
      final c = PrediccionDto.fromJson(_respuesta(tendencia: 'sin_base', pct: null)).toEntity().comparacion;
      expect(c.tendencia, Tendencia.sinBase);
      expect(c.variacionPorcentual, isNull);
    });

    test('estable y disminucion', () {
      expect(Tendencia.fromApi('estable'), Tendencia.estable);
      expect(Tendencia.fromApi('disminucion'), Tendencia.disminucion);
    });
  });

  group('FichaModeloDto', () {
    test('calcula los límites del selector de mes', () {
      final f = const FichaModeloDto({
        'nombre': 'RNA-MLP demanda mensual GAV',
        'version': '1.0.0',
        'entrenado_en': '2026-11-18T21:02:09+00:00',
        'origen_serie': '2021-01',
        'ultimo_mes_real': '2026-10',
        'horizonte_disponible_hasta': '2027-10',
        'metricas': {'mae': 16.4, 'rmse': 20.85, 'mape': 2.36},
      }).toEntity();

      expect(f.primerPronostico, const Periodo(2026, 11));
      expect(f.primerConsultable, const Periodo(2023, 3));
      expect(f.admite(const Periodo(2027, 10)), isTrue);
      expect(f.admite(const Periodo(2027, 11)), isFalse);
      expect(f.rmse, closeTo(20.85, 0.001));
    });
  });

  group('Periodo', () {
    test('cruza de año al sumar meses', () {
      expect(const Periodo(2026, 12).siguiente, const Periodo(2027, 1));
      expect(const Periodo(2027, 1).anterior, const Periodo(2026, 12));
      expect(const Periodo(2027, 2).dias, 28);
      expect(Periodo.tryParse('2027-13'), isNull);
      expect(Periodo.tryParse('2027-03')!.api, '2027-03');
    });
  });
}
