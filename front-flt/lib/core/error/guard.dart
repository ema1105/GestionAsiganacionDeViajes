import 'package:dio/dio.dart';

import '../network/api_paths.dart';
import 'app_failure.dart';

/// Ejecuta una llamada de red y convierte cualquier error técnico en [AppFailure].
/// Es el ÚNICO punto donde se atrapan excepciones de red (se usa en los repositorios).
Future<T> guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on AppFailure {
    rethrow;
  } on DioException catch (e) {
    throw mapDioException(e);
  } on TypeError {
    // p. ej. "type 'int' is not a subtype of type 'String'" al parsear JSON.
    throw const ParsingFailure();
  } on FormatException {
    throw const ParsingFailure();
  }
}

AppFailure mapDioException(DioException e) {
  // Un interceptor puede haber adjuntado ya un AppFailure (p. ej. token expirado).
  final adjunto = e.error;
  if (adjunto is AppFailure) return adjunto;

  // Cualquier variante de timeout (connection/send/receive/transform y las que
  // agreguen futuras versiones de Dio) se trata igual.
  if (e.type.name.toLowerCase().contains('timeout')) {
    return const RequestTimeoutFailure();
  }
  if (e.type == DioExceptionType.connectionError) return const NetworkFailure();
  if (e.type == DioExceptionType.unknown && e.response == null) {
    return const NetworkFailure();
  }

  final status = e.response?.statusCode;
  final body = e.response?.data;
  final String? mensaje = body is Map && body['mensaje'] is String ? body['mensaje'] as String : null;
  final esAuthPublica = e.requestOptions.path.startsWith(ApiPaths.authPrefix);

  if (status == 400 && body is Map && body['errores'] is Map) {
    final errores = (body['errores'] as Map).map((k, v) => MapEntry('$k', '$v'));
    return ValidationFailure(mensaje ?? 'Revisa los datos ingresados.', errores);
  }

  return switch (status) {
    401 when esAuthPublica => InvalidCredentialsFailure(mensaje ?? 'Credenciales inválidas'),
    401 => const UnauthorizedFailure(),
    403 => ForbiddenFailure(mensaje ?? 'No tienes permiso para esta acción.'),
    404 => NotFoundFailure(mensaje ?? 'Recurso no encontrado.'),
    409 => ConflictFailure(mensaje ?? 'La operación entra en conflicto con el estado actual.'),
    final int s when s >= 500 => const ServerFailure(),
    final int s when s >= 400 => BusinessFailure(s, mensaje ?? 'Solicitud inválida.'),
    _ => UnknownFailure(mensaje ?? 'Ocurrió un error inesperado.'),
  };
}
