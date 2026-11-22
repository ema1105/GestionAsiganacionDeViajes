import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';
import '../../domain/entities/sesion.dart';

/// Estado global de la sesión. null = no autenticado.
/// El router escucha este provider para redirigir según el rol.
class SesionController extends AsyncNotifier<Sesion?> {
  /// true cuando la sesión terminó por expiración/401 (para avisar en el login).
  bool expiroPorTiempo = false;

  @override
  Future<Sesion?> build() => ref.read(authRepositoryProvider).sesionGuardada();

  /// Lanza AppFailure si falla: la pantalla de login lo muestra.
  Future<void> login(String nombreUsuario, String contrasena) async {
    final sesion = await ref.read(authRepositoryProvider).login(nombreUsuario, contrasena);
    expiroPorTiempo = false;
    state = AsyncData(sesion);
  }

  Future<void> registrar(RegistroCliente datos) async {
    final sesion = await ref.read(authRepositoryProvider).registrarCliente(datos);
    expiroPorTiempo = false;
    state = AsyncData(sesion);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    expiroPorTiempo = false;
    state = const AsyncData(null);
  }

  /// Llamado por AuthInterceptor ante un 401 o un token vencido.
  void marcarExpirada() {
    if (state.value == null) return;
    expiroPorTiempo = true;
    state = const AsyncData(null);
  }
}

final sesionControllerProvider =
    AsyncNotifierProvider<SesionController, Sesion?>(SesionController.new);
