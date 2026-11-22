import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../error/app_failure.dart';
import '../storage/token_storage.dart';
import 'api_paths.dart';

/// Adjunta `Authorization: Bearer <jwt>` y gestiona el cierre de sesión.
///
/// - Expiración preventiva: si el JWT ya venció, no se envía la petición.
/// - 401 fuera de /api/auth → limpia el token y notifica (sesión expirada).
/// - 401 en /api/auth/login → NO es sesión expirada (credenciales / cuenta deshabilitada).
/// - 403 → se deja pasar; el usuario sigue autenticado.
///
/// Es `QueuedInterceptor`: cuando el backend tenga `/api/auth/refresh`,
/// el refresco se hará una sola vez aunque fallen varias peticiones en paralelo.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._storage, {required this.onSessionExpired});

  final TokenStorage _storage;
  final void Function() onSessionExpired;

  bool _esPublica(RequestOptions o) => o.path.startsWith(ApiPaths.authPrefix);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_esPublica(options)) return handler.next(options);

    final token = await _storage.read();
    if (token == null || token.isEmpty) {
      options.headers.remove('Authorization');
      return handler.next(options);
    }

    if (_expirado(token)) {
      await _storage.clear();
      onSessionExpired();
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: const UnauthorizedFailure(),
        ),
      );
    }

    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_esPublica(err.requestOptions)) {
      await _storage.clear();
      onSessionExpired();
    }
    handler.next(err);
  }

  bool _expirado(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true; // token corrupto = sesión inválida
    }
  }
}
