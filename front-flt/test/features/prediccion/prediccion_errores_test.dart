import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gav_app/core/error/app_failure.dart';
import 'package:gav_app/features/prediccion/data/prediccion_errores.dart';

DioException _respuesta(int status, Object? body) {
  final req = RequestOptions(path: '/api/prediccion/mensual');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(requestOptions: req, statusCode: status, data: body),
  );
}

void main() {
  group('mapPrediccionException — formato de errores de FastAPI', () {
    test('422 de negocio muestra el detail del servicio', () {
      final f = mapPrediccionException(
        _respuesta(422, {'detail': 'nov 2027 supera el horizonte máximo (oct 2027).'}),
      );
      expect(f, isA<BusinessFailure>());
      expect(f.message, contains('horizonte'));
    });

    test('422 de validación (lista) → ValidationFailure por parámetro', () {
      final f = mapPrediccionException(
        _respuesta(422, {
          'detail': [
            {'loc': ['query', 'mes'], 'msg': 'Input should be less than or equal to 12'},
          ],
        }),
      );
      expect(f, isA<ValidationFailure>());
      expect((f as ValidationFailure).fieldErrors['mes'], contains('12'));
    });

    test('401 no se confunde con la sesión expirada', () {
      final f = mapPrediccionException(_respuesta(401, {'detail': 'API key inválida o ausente.'}));
      expect(f, isA<BusinessFailure>());
      expect(f, isNot(isA<UnauthorizedFailure>()));
    });

    test('503 (modelo no cargado) es reintentable', () {
      final f = mapPrediccionException(_respuesta(503, {'detail': 'Modelo no cargado.'}));
      expect(f, isA<ServerFailure>());
      expect(f.isRetryable, isTrue);
    });

    test('sin respuesta → NetworkFailure', () {
      final f = mapPrediccionException(
        DioException(
          requestOptions: RequestOptions(path: '/api/prediccion/salud'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(f, isA<NetworkFailure>());
    });
  });
}
