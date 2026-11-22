import '../config/env.dart';

/// Lectores tolerantes para el JSON de Spring/Jackson.
///
/// - `BigDecimal` llega como número JSON: `4` (int) o `4.5` (double) → siempre `num`.
/// - `Long` llega como int.
/// - `LocalDateTime` llega SIN zona: "2026-11-18T22:14:05.123".

double? asDouble(Object? v) => switch (v) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s),
      _ => null,
    };

double reqDouble(Object? v, String campo) =>
    asDouble(v) ?? (throw FormatException('Campo numérico requerido: $campo'));

int? asInt(Object? v) => switch (v) {
      final int n => n,
      final num n => n.toInt(),
      final String s => int.tryParse(s),
      _ => null,
    };

int reqInt(Object? v, String campo) =>
    asInt(v) ?? (throw FormatException('Campo entero requerido: $campo'));

String? asString(Object? v) => v?.toString();

bool asBool(Object? v, {bool orElse = false}) => switch (v) {
      final bool b => b,
      final String s => s.toLowerCase() == 'true',
      _ => orElse,
    };

final _conZona = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

/// Interpreta las fechas del backend. Si no traen zona, se asume la del servidor
/// ([Env.serverOffsetHours]) y se convierte a la hora local del dispositivo.
DateTime? asServerDateTime(Object? v) {
  if (v is! String || v.isEmpty) return null;
  final iso = _conZona.hasMatch(v) ? v : '$v${_offsetIso(Env.serverOffsetHours)}';
  return DateTime.tryParse(iso)?.toLocal();
}

/// Formato para `@RequestParam LocalDateTime` (desde/hasta):
/// ISO sin zona, expresado en la hora del servidor. Ej: 2026-11-18T22:14:05
String toServerIso(DateTime d) => d
    .toUtc()
    .add(Duration(hours: Env.serverOffsetHours))
    .toIso8601String()
    .replaceFirst('Z', '')
    .split('.')
    .first;

String _offsetIso(int horas) {
  final signo = horas < 0 ? '-' : '+';
  return '$signo${horas.abs().toString().padLeft(2, '0')}:00';
}
