import 'entities/sesion.dart';

abstract interface class AuthRepository {
  /// Lanza [InvalidCredentialsFailure] si las credenciales son incorrectas
  /// o la cuenta está deshabilitada.
  Future<Sesion> login(String nombreUsuario, String contrasena);

  /// Sesión persistida y vigente, o null.
  Future<Sesion?> sesionGuardada();

  Future<void> logout();

  /// Registra un cliente y deja la sesión iniciada.
  Future<Sesion> registrarCliente(RegistroCliente datos);
}

class RegistroCliente {
  const RegistroCliente({
    required this.nombreCompleto,
    required this.apellidosCompletos,
    required this.email,
    required this.telefono,
    required this.contrasena,
    required this.nombreUsuario,
    required this.numeroDocumento,
    required this.fechaNacimiento,
    this.tipoDocumento = 'CC',
  });

  final String nombreCompleto;
  final String apellidosCompletos;
  final String email;
  final String telefono;
  final String contrasena;
  final String nombreUsuario;
  final String numeroDocumento;
  final String tipoDocumento;
  final DateTime fechaNacimiento;

  Map<String, dynamic> toJson() => {
        'nombreCompleto': nombreCompleto.trim(),
        'apellidosCompletos': apellidosCompletos.trim(),
        'email': email.trim(),
        'telefono': telefono.trim(),
        'contrasena': contrasena,
        'nombreUsuario': nombreUsuario.trim(),
        'tipoDocumento': tipoDocumento,
        'numeroDocumento': numeroDocumento.trim(),
        'fechaNacimiento': fechaNacimiento.toIso8601String().substring(0, 10),
      };
}
