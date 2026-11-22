import 'package:intl/intl.dart';

/// Formatos de presentación en español (Colombia).
abstract final class Fmt {
  // "45.000" (punto de miles); el símbolo se antepone a mano: "$45.000".
  static final _miles = NumberFormat('#,##0', 'es');
  static final _fechaCorta = DateFormat("d MMM',' HH:mm", 'es');
  static final _fechaLarga = DateFormat("d 'de' MMMM 'de' y", 'es');
  static final _hora = DateFormat('HH:mm', 'es');
  static final _fechaHora = DateFormat("d MMM y',' HH:mm", 'es');
  static final _unDecimal = NumberFormat('#,##0.0', 'es');

  static String pesos(num? v) => v == null ? '—' : '\$${_miles.format(v.round())}';
  static String miles(num? v) => v == null ? '—' : _miles.format(v);

  /// "27 oct, 09:10"
  static String fechaCorta(DateTime? d) => d == null ? '—' : _fechaCorta.format(d).replaceAll('.', '');

  /// "27 de octubre de 2026"
  static String fechaLarga(DateTime? d) => d == null ? '—' : _fechaLarga.format(d);

  static String hora(DateTime? d) => d == null ? '—' : _hora.format(d);

  /// "18 nov 2026, 16:02"
  static String fechaHora(DateTime? d) => d == null ? '—' : _fechaHora.format(d).replaceAll('.', '');

  /// "18,5"
  static String unDecimal(num? v) => v == null ? '—' : _unDecimal.format(v);

  static const meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const mesesCortos = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  static String mes(int m) => meses[m - 1];
  static String mesCorto(int m) => mesesCortos[m - 1];

  /// "Hace 5 min", "Hace 2 h", "Ayer", "Hace 3 días"
  static String relativo(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return fechaCorta(d);
  }

  /// Variación porcentual; null si no hay base de comparación.
  static double? variacion(num actual, num anterior) =>
      anterior == 0 ? null : (actual - anterior) * 100 / anterior;
}
