import 'rol.dart';

/// Usuario autenticado. Se reconstruye desde el JWT al reabrir la app.
class Sesion {
  const Sesion({required this.nombreUsuario, required this.rol, this.expiraEn});

  final String nombreUsuario;
  final Rol rol;
  final DateTime? expiraEn;

  /// Minutos restantes de sesión (no hay refresh token: avisar antes de que caduque).
  int? get minutosRestantes => expiraEn?.difference(DateTime.now()).inMinutes;
}
