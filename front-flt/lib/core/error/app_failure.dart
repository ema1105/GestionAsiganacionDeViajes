/// Errores tipados de la app. La UI SOLO conoce estos tipos (nunca DioException).
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  /// Mensaje apto para mostrar al usuario.
  final String message;

  /// Solo errores transitorios se reintentan (red, timeout, 5xx). Nunca 4xx.
  bool get isRetryable =>
      this is NetworkFailure || this is RequestTimeoutFailure || this is ServerFailure;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure() : super('Sin conexión con el servidor. Revisa tu red.');
}

final class RequestTimeoutFailure extends AppFailure {
  const RequestTimeoutFailure() : super('El servidor tardó demasiado en responder.');
}

/// 401 fuera de /api/auth: sesión ausente, expirada o token inválido.
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Tu sesión expiró. Inicia sesión nuevamente.']);
}

/// 401 en /api/auth/login: credenciales inválidas o cuenta deshabilitada.
final class InvalidCredentialsFailure extends AppFailure {
  const InvalidCredentialsFailure([super.message = 'Credenciales inválidas']);
}

/// 403: autenticado, pero el rol no tiene permiso. NO cierra sesión.
final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([super.message = 'No tienes permiso para esta acción.']);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Recurso no encontrado.']);
}

/// 409: p. ej. DataIntegrityViolation o un viaje que ya cambió de estado.
final class ConflictFailure extends AppFailure {
  const ConflictFailure([super.message = 'La operación entra en conflicto con el estado actual.']);
}

/// 400 con `errores: {campo: mensaje}` (Bean Validation en el backend).
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, this.fieldErrors);

  /// Claves = nombres de campo del DTO Java (p. ej. `cantidadPasajeros`).
  final Map<String, String> fieldErrors;
}

/// Otros 4xx de negocio (BusinessException con su status).
final class BusinessFailure extends AppFailure {
  const BusinessFailure(this.status, super.message);
  final int status;
}

/// 5xx. Nunca mostramos el mensaje del backend (filtra detalles internos).
final class ServerFailure extends AppFailure {
  const ServerFailure() : super('El servidor tuvo un problema. Intenta de nuevo.');
}

/// La respuesta no tiene la forma esperada (contrato roto o cambio en el backend).
final class ParsingFailure extends AppFailure {
  const ParsingFailure() : super('Respuesta inesperada del servidor.');
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Ocurrió un error inesperado.']);
}

/// Mensaje para cualquier objeto de error (útil en `AsyncValue.error`).
String userMessageOf(Object error) =>
    error is AppFailure ? error.message : const UnknownFailure().message;
