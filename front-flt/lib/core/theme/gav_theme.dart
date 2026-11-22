import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'gav_colors.dart';

/// Tipografías de los mockups: serif para títulos, sans para el resto.
/// Para cambiarlas, basta con editar estos dos nombres (Google Fonts).
abstract final class GavFonts {
  static const serif = 'Source Serif 4';
  static const sans = 'DM Sans';

  /// En tests se desactiva para no descargar fuentes por red.
  static bool usarGoogleFonts = true;

  static TextStyle get({
    required String family,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    Color? color,
  }) {
    if (!usarGoogleFonts) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );
    }
    return GoogleFonts.getFont(
      family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }
}

abstract final class GavText {
  /// Título grande de pantalla ("Inicio", "Panel", "Mi perfil").
  static TextStyle title(BuildContext c, {double size = 30}) => GavFonts.get(
        family: GavFonts.serif,
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.15,
        color: c.gav.text,
      );

  /// Etiqueta superior dorada en mayúsculas ("GAV · CONDUCTOR").
  static TextStyle eyebrow(BuildContext c) => GavFonts.get(
        family: GavFonts.sans,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: c.gav.gold,
      );

  /// Etiqueta pequeña en mayúsculas de campos y KPIs ("NOMBRE DE USUARIO").
  static TextStyle label(BuildContext c) => GavFonts.get(
        family: GavFonts.sans,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: c.gav.textFaint,
      );

  static TextStyle body(BuildContext c, {Color? color, double size = 14, FontWeight? weight}) =>
      GavFonts.get(
        family: GavFonts.sans,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? c.gav.text,
      );

  static TextStyle muted(BuildContext c, {double size = 12.5}) =>
      body(c, color: c.gav.textMuted, size: size);

  static TextStyle strong(BuildContext c, {double size = 15}) =>
      body(c, size: size, weight: FontWeight.w700);

  /// Números grandes de KPIs ("574", "$45.000").
  static TextStyle kpi(BuildContext c, {double size = 28, Color? color}) => GavFonts.get(
        family: GavFonts.sans,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? c.gav.text,
      );
}

ThemeData buildGavTheme(Brightness brightness) {
  final g = brightness == Brightness.dark ? GavColors.dark : GavColors.light;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  // google_fonts todavía tipa TextTheme con el material antiguo; con material_ui
  // se aplica solo la familia tipográfica (TextStyle sí es compartido).
  final familiaSans = GavFonts.usarGoogleFonts ? GoogleFonts.getFont(GavFonts.sans).fontFamily : null;
  final textTheme = base.textTheme.apply(
    fontFamily: familiaSans,
    bodyColor: g.text,
    displayColor: g.text,
  );

  return base.copyWith(
    scaffoldBackgroundColor: g.background,
    canvasColor: g.background,
    textTheme: textTheme,
    extensions: [g],
    colorScheme: ColorScheme.fromSeed(
      seedColor: g.gold,
      brightness: brightness,
      surface: g.surface,
      primary: g.gold,
      error: g.danger,
    ),
    dividerTheme: DividerThemeData(color: g.border, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: g.gold),
    appBarTheme: AppBarTheme(
      backgroundColor: g.background,
      foregroundColor: g.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: g.surfaceAlt,
      contentTextStyle: TextStyle(color: g.text),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: g.surface,
      hintStyle: TextStyle(color: g.textFaint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: g.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: g.gold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: g.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: g.danger),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? g.onPrimaryButton : g.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? g.gold : g.surfaceAlt,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? g.gold : Colors.transparent,
      ),
      side: BorderSide(color: g.textFaint),
    ),
    dialogTheme: DialogThemeData(backgroundColor: g.surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: g.surface),
  );
}
