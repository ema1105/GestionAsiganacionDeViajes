import 'package:dio/dio.dart';

import '../dtos/prediccion_dto.dart';

/// Rutas del prediction-service (FastAPI). Solo HTTP, sin lógica.
abstract final class PrediccionPaths {
  static const mensual = '/api/prediccion/mensual';
  static const modelo = '/api/prediccion/modelo';
  static const salud = '/api/prediccion/salud';
}

class PrediccionRemoteDataSource {
  PrediccionRemoteDataSource(this._dio);
  final Dio _dio;

  /// `mes_fin` se omite para un solo mes. `anio_base` usa el valor por defecto (anio − 1).
  Future<PrediccionDto> mensual({required int anio, required int mes, int? mesFin}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      PrediccionPaths.mensual,
      queryParameters: {
        'anio': anio,
        'mes': mes,
        if (mesFin != null && mesFin != mes) 'mes_fin': mesFin,
      },
    );
    return PrediccionDto.fromJson(res.data!);
  }

  Future<FichaModeloDto> modelo() async {
    final res = await _dio.get<Map<String, dynamic>>(PrediccionPaths.modelo);
    return FichaModeloDto(res.data!);
  }

  /// `{"estado": "ok" | "sin_modelo"}`
  Future<String?> salud() async {
    final res = await _dio.get<Map<String, dynamic>>(PrediccionPaths.salud);
    return res.data?['estado']?.toString();
  }
}
