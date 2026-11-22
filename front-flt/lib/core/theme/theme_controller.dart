import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema claro/oscuro con persistencia. Por defecto: oscuro (como los mockups).
class ThemeController extends Notifier<ThemeMode> {
  static const _key = 'gav_theme_mode';

  @override
  ThemeMode build() {
    _cargar();
    return ThemeMode.dark;
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_key);
    if (guardado == 'light') state = ThemeMode.light;
  }

  bool get esOscuro => state == ThemeMode.dark;

  Future<void> alternar() => establecer(oscuro: state != ThemeMode.dark);

  Future<void> establecer({required bool oscuro}) async {
    state = oscuro ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, oscuro ? 'dark' : 'light');
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
