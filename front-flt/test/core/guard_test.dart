import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gav_app/core/error/app_failure.dart';
import 'package:gav_app/core/error/guard.dart';

DioException _respuesta(int status, Object? body, {String path = '/api/cliente/viajes'}) {
  final req = RequestOptions(path: path);
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(requestOptions: req, statusCode: status, data: body),
  );
}

void main() {
  group('mapDioException — formato de errores del GlobalExceptionHandler', () {
    test('400 con errores de campo → ValidationFailure', () {
      final f = mapDioException(_respuesta(400, {
        'status': 400,
        'mensaje': 'Errores de validación',
        'errores': {'cantidadPasajeros': 'Debe haber al menos 1 pasajero'},
      }));
      expect(f, isA<ValidationFailure>());
      expect((f as ValidationFailure).fieldErrors['cantidadPasajeros'], contains('al menos 1'));
    });

    test('401 en login → credenciales inválidas (no sesión expirada)', () {
      final f = mapDioException(
        _respuesta(401, {'mensaje': 'Tu cuenta está deshabilitada.'}, path: '/api/auth/login'),
      );
      expect(f, isA<InvalidCredentialsFailure>());
      expect(f.message, 'Tu cuenta está deshabilitada.');
    });

    test('401 en endpoint protegido → UnauthorizedFailure', () {
      expect(mapDioException(_respuesta(401, null)), isA<UnauthorizedFailure>());
    });

    test('403 → ForbiddenFailure', () {
      expect(mapDioException(_respuesta(403, {'mensaje': 'Acceso denegado'})), isA<ForbiddenFailure>());
    });

    test('409 conserva el mensaje del backend', () {
      final f = mapDioException(_respuesta(409, {'mensaje': 'El recurso tiene referencias'}));
      expect(f, isA<ConflictFailure>());
      expect(f.message, 'El recurso tiene referencias');
    });

    test('500 NO expone el mensaje interno', () {
      final f = mapDioException(_respuesta(500, {'mensaje': 'Error interno: NullPointerException'}));
      expect(f, isA<ServerFailure>());
      expect(f.message, isNot(contains('NullPointer')));
      expect(f.isRetryable, isTrue);
    });

    test('timeout y sin conexión', () {
      final req = RequestOptions(path: '/x');
      expect(
        mapDioException(DioException(requestOptions: req, type: DioExceptionType.receiveTimeout)),
        isA<RequestTimeoutFailure>(),
      );
      expect(
        mapDioException(DioException(requestOptions: req, type: DioExceptionType.connectionError)),
        isA<NetworkFailure>(),
      );
    });
  });

  test('guard convierte errores de parseo en ParsingFailure', () async {
    final Map<String, dynamic> json = {'id': 'abc'};
    await expectLater(
      guard<int>(() async => json['id'] as int),
      throwsA(isA<ParsingFailure>()),
    );
  });
}
