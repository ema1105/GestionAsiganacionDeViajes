import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'prediccion_demo_interceptor.dart';

/// Cliente HTTP del servicio de predicción (FastAPI).
///
/// Es independiente de [dioProvider]: otra URL base, sin JWT de Spring y sin
/// cerrar la sesión ante un 401 (ese 401 sería de la API key del servicio).
final prediccionDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.prediccionBaseUrl,
      connectTimeout: Env.connectTimeout,
      sendTimeout: Env.receiveTimeout,
      receiveTimeout: Env.prediccionTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: {
        if (Env.prediccionApiKey.isNotEmpty) 'Authorization': 'Bearer ${Env.prediccionApiKey}',
      },
    ),
  );

  // Respaldo demo para la presentación (ver prediccion_demo_interceptor.dart)
  dio.interceptors.add(PrediccionDemoInterceptor());

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: true,
        requestHeader: false, // no imprimir la API key
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }

  ref.onDispose(dio.close);
  return dio;
});
