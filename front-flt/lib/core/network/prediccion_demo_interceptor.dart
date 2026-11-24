import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../config/env.dart';

/// Respaldo para la presentación del prediction-service.
///
/// - `DEMO_MODE=true`: las consultas GET de predicción nunca salen a la red;
///   se responden con los JSON de `assets/demo/` (respuestas reales del modelo,
///   generadas con los mismos artefactos que corren en la nube).
/// - `FALLBACK_DEMO=true` (por defecto): si la nube no responde (sin red,
///   timeout o error 5xx) se usa el mismo JSON en lugar de mostrar un error.
///   Los errores 4xx (periodo inválido, 401 de la API key) NO se ocultan.
///
/// Solo cubre lecturas: reentrenar/restaurar (POST) siempre van a la red.
class PrediccionDemoInterceptor extends Interceptor {
  static const _assetMensual = 'assets/demo/prediccion_mensual.json';
  static const _assetModelo = 'assets/demo/prediccion_modelo.json';

  static const _errorDeRed = {
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.unknown,
  };

  Map<String, dynamic>? _mensuales;

  bool _cubre(RequestOptions o) =>
      o.method == 'GET' &&
      (o.path.endsWith('/api/prediccion/mensual') ||
          o.path.endsWith('/api/prediccion/modelo') ||
          o.path.endsWith('/api/prediccion/salud'));

  Future<Response<dynamic>> _demo(RequestOptions o) async {
    final Object data;
    if (o.path.endsWith('/salud')) {
      data = {'estado': 'ok'};
    } else if (o.path.endsWith('/modelo')) {
      data = jsonDecode(await rootBundle.loadString(_assetModelo)) as Object;
    } else {
      _mensuales ??= jsonDecode(await rootBundle.loadString(_assetMensual)) as Map<String, dynamic>;
      final q = o.queryParameters;
      final anio = q['anio'];
      final mes = q['mes'].toString().padLeft(2, '0');
      final fin = q['mes_fin'];
      final clave = fin == null ? '$anio-$mes' : '$anio-${mes}_${fin.toString().padLeft(2, '0')}';
      data = (_mensuales![clave] ?? _mensuales!['2027-10'] ?? _mensuales!.values.first) as Object;
    }
    return Response<dynamic>(
      requestOptions: o,
      data: data,
      statusCode: 200,
      headers: Headers.fromMap({
        'x-gav-demo': ['true'],
      }),
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (Env.demoMode && _cubre(options)) {
      handler.resolve(await _demo(options));
      return;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final o = err.requestOptions;
    final sinNube = _errorDeRed.contains(err.type) || (err.response?.statusCode ?? 0) >= 500;
    if (Env.fallbackDemo && sinNube && _cubre(o)) {
      handler.resolve(await _demo(o));
      return;
    }
    handler.next(err);
  }
}
