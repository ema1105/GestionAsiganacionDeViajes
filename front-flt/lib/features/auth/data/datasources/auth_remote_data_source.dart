import 'package:dio/dio.dart';

import '../../../../core/network/api_paths.dart';
import '../dtos/login_response_dto.dart';

/// Solo HTTP + deserialización. Sin lógica ni manejo de errores.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<LoginResponseDto> login(String nombreUsuario, String contrasena) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiPaths.login,
      data: {'nombreUsuario': nombreUsuario, 'contrasena': contrasena},
    );
    return LoginResponseDto.fromJson(res.data!);
  }

  /// POST /api/auth/register/cliente (RegisterClienteRequest).
  Future<void> registrarCliente(Map<String, dynamic> body) =>
      _dio.post<void>(ApiPaths.registerCliente, data: body);
}
