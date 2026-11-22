import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../core/error/guard.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/rol.dart';
import '../domain/entities/sesion.dart';
import 'datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  @override
  Future<Sesion> login(String nombreUsuario, String contrasena) => guard(() async {
        final dto = await _remote.login(nombreUsuario.trim(), contrasena);
        await _storage.save(dto.token);
        return _sesionDesdeToken(
          dto.token,
          nombreUsuario: dto.nombreUsuario,
          rol: Rol.fromApi(dto.rol),
        );
      });

  @override
  Future<Sesion?> sesionGuardada() async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) return null;
    try {
      if (JwtDecoder.isExpired(token)) {
        await _storage.clear();
        return null;
      }
      return _sesionDesdeToken(token);
    } catch (_) {
      await _storage.clear(); // token corrupto
      return null;
    }
  }

  @override
  Future<void> logout() => _storage.clear();

  @override
  Future<Sesion> registrarCliente(RegistroCliente datos) async {
    await guard(() => _remote.registrarCliente(datos.toJson()));
    return login(datos.nombreUsuario, datos.contrasena);
  }

  /// Claims del backend (JwtService): sub = nombre de usuario, rol = ROLE_XXX.
  Sesion _sesionDesdeToken(String token, {String? nombreUsuario, Rol? rol}) {
    final claims = JwtDecoder.decode(token);
    return Sesion(
      nombreUsuario: (nombreUsuario?.isNotEmpty ?? false)
          ? nombreUsuario!
          : (claims['sub']?.toString() ?? ''),
      rol: rol ?? Rol.fromApi(claims['rol']?.toString()),
      expiraEn: JwtDecoder.getExpirationDate(token),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(dioProvider)),
    ref.watch(tokenStorageProvider),
  ),
);
