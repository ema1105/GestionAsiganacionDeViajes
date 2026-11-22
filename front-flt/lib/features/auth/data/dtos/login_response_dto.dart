import '../../../../core/json/json_read.dart';

/// Espejo de `LoginResponse` (Spring): { token, tipo, nombreUsuario, rol }.
class LoginResponseDto {
  const LoginResponseDto({
    required this.token,
    required this.tipo,
    required this.nombreUsuario,
    required this.rol,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final token = asString(json['token']);
    if (token == null || token.isEmpty) throw const FormatException('Login sin token');
    return LoginResponseDto(
      token: token,
      tipo: asString(json['tipo']) ?? 'Bearer',
      nombreUsuario: asString(json['nombreUsuario']) ?? '',
      rol: asString(json['rol']) ?? '',
    );
  }

  final String token;
  final String tipo;
  final String nombreUsuario;
  final String rol;
}
