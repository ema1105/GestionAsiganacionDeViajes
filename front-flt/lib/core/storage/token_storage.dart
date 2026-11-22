import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el JWT en Keystore (Android) / Keychain (iOS).
/// Mantiene una copia en memoria para no leer del almacenamiento en cada request.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'gav_token';
  final FlutterSecureStorage _storage;
  String? _cache;
  bool _cargado = false;

  Future<String?> read() async {
    if (!_cargado) {
      _cache = await _storage.read(key: _key);
      _cargado = true;
    }
    return _cache;
  }

  Future<void> save(String token) async {
    _cache = token.trim();
    _cargado = true;
    await _storage.write(key: _key, value: _cache);
  }

  Future<void> clear() async {
    _cache = null;
    _cargado = true;
    await _storage.delete(key: _key);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
