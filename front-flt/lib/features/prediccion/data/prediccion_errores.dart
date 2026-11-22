import 'package:dio/dio.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/guard.dart';

/// Equivalente de [guard] para el servicio de predicción (FastAPI).
///
/// FastAPI responde los errores como `{"detail": "texto"}` o, en la validación
/// de parámetros, `{"detail": [{"loc": [...], "msg": "..."}]}`. El mapeo de
/// Spring ([mapDioException]) busca `mensaje`/`errores`, así que aquí se traduce aparte.
Future<T> guardPrediccion<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on AppFailure {
    rethrow;
  } on DioException catch (e) {
    throw mapPrediccionException(e);
  } on TypeError {
    throw const ParsingFailure();
  } on FormatException {
    throw const ParsingFailure();
  }
}

AppFailure mapPrediccionException(DioException e) {
  final res = e.response;
  // Sin respuesta (red, timeout, cancelación): el mapeo general ya lo resuelve.
  if (res == null) return mapDioException(e);

  final status = res.statusCode ?? 0;
  final data = res.data;
  final detail = data is Map<String, dynamic> ? data['detail'] : null;
  final texto = detail is String && detail.trim().isNotEmpty ? detail.trim() : null;

  // 422 de validación de FastAPI: lista de errores por parámetro.
  if (status == 422 && detail is List) {
    final errores = <String, String>{
      for (final err in detail.whereType<Map<String, dynamic>>())
        _campo(err['loc']): '${err['msg'] ?? 'Valor inválido'}',
    };
    return ValidationFailure('Parámetros inválidos para la predicción.', errores);
  }

  return switch (status) {
    // 422 de negocio: base sin datos reales, fuera del horizonte, anio_base ≥ anio.
    422 => BusinessFailure(422, texto ?? 'No se puede predecir ese periodo.'),
    // Solo ocurre si el servicio tiene GAV_API_KEY. No es la sesión del usuario.
    401 => const BusinessFailure(
        401,
        'El servicio de predicción rechazó la API key. Revisa PREDICCION_API_KEY.',
      ),
    404 => const NotFoundFailure('El servicio de predicción no tiene esa ruta. ¿Versión correcta?'),
    409 => ConflictFailure(texto ?? 'Hay un entrenamiento en curso.'),
    // 503 = modelo no cargado. ServerFailure se reintenta solo.
    >= 500 => const ServerFailure(),
    >= 400 => BusinessFailure(status, texto ?? 'Solicitud inválida.'),
    _ => UnknownFailure(texto ?? 'Ocurrió un error inesperado.'),
  };
}

String _campo(Object? loc) =>
    loc is List && loc.isNotEmpty ? '${loc.last}' : 'parametro';
