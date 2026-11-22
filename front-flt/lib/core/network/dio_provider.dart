import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/sesion_controller.dart';
import '../config/env.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP único de la app. Todas las llamadas pasan por aquí.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: Env.connectTimeout,
      sendTimeout: Env.receiveTimeout,
      receiveTimeout: Env.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      ref.read(tokenStorageProvider),
      // Lectura diferida: evita la dependencia circular dio ↔ sesión al construir.
      onSessionExpired: () => ref.read(sesionControllerProvider.notifier).marcarExpirada(),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false, // no imprimir el JWT en consola
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }

  ref.onDispose(dio.close);
  return dio;
});
