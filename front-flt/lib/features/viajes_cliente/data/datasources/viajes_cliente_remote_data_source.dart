import 'package:dio/dio.dart';

import '../../../../core/json/json_read.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/pagination/pagina.dart';
import '../../domain/entities/estado_viaje.dart';
import '../dtos/viaje_dto.dart';

class ViajesClienteRemoteDataSource {
  ViajesClienteRemoteDataSource(this._dio);
  final Dio _dio;

  /// 204 No Content → null.
  Future<ViajeDto?> viajeActivo() async {
    final res = await _dio.get<dynamic>(ApiPaths.clienteViajeActivo);
    final data = res.data;
    if (res.statusCode == 204 || data is! Map<String, dynamic>) return null;
    return ViajeDto.fromJson(data);
  }

  Future<PageDto<ViajeDto>> historial({
    EstadoViaje? estado,
    DateTime? desde,
    DateTime? hasta,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiPaths.clienteViajes,
      queryParameters: {
        if (estado != null) 'estado': estado.api,
        if (desde != null) 'desde': toServerIso(desde),
        if (hasta != null) 'hasta': toServerIso(hasta),
        'page': page,
        'size': size,
      },
    );
    return PageDto.fromJson(res.data!, ViajeDto.fromJson);
  }

  Future<void> cancelar(int viajeId) => _dio.post<void>(ApiPaths.clienteCancelar(viajeId));

  /// 204 cuando el viaje aún no tiene puntos GPS → null (no es error).
  Future<PuntoSeguimientoDto?> ultimoPunto(int viajeId) async {
    final res = await _dio.get<dynamic>(ApiPaths.clienteUltimoPunto(viajeId));
    final data = res.data;
    if (res.statusCode == 204 || data is! Map<String, dynamic>) return null;
    return PuntoSeguimientoDto.fromJson(data);
  }
}
