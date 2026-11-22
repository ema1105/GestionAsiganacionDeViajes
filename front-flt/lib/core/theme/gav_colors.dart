import 'package:material_ui/material_ui.dart';

/// Tokens de color de GAV (extraídos de los mockups de Figma).
/// Se accede con `context.gav` desde cualquier widget.
@immutable
class GavColors extends ThemeExtension<GavColors> {
  const GavColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.gold,
    required this.goldContainer,
    required this.goldOnContainer,
    required this.primaryButton,
    required this.onPrimaryButton,
    required this.success,
    required this.successContainer,
    required this.danger,
    required this.dangerContainer,
    required this.neutralChip,
    required this.onNeutralChip,
    required this.warmChip,
    required this.onWarmChip,
    required this.navBackground,
    required this.navSelected,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color gold;
  final Color goldContainer;
  final Color goldOnContainer;
  final Color primaryButton;
  final Color onPrimaryButton;
  final Color success;
  final Color successContainer;
  final Color danger;
  final Color dangerContainer;
  final Color neutralChip;
  final Color onNeutralChip;
  final Color warmChip;
  final Color onWarmChip;
  final Color navBackground;
  final Color navSelected;

  /// Tema oscuro: idéntico a los mockups.
  static const dark = GavColors(
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF141414),
    surfaceAlt: Color(0xFF1C1C1B),
    border: Color(0xFF242322),
    text: Color(0xFFF2EFE9),
    textMuted: Color(0xFF9C9891),
    textFaint: Color(0xFF67645F),
    gold: Color(0xFFA98845),
    goldContainer: Color(0xFF2C271C),
    goldOnContainer: Color(0xFFC9A964),
    primaryButton: Color(0xFFF2EFE9),
    onPrimaryButton: Color(0xFF141414),
    success: Color(0xFF34C46A),
    successContainer: Color(0xFF12301E),
    danger: Color(0xFFE5534B),
    dangerContainer: Color(0xFF3A1717),
    neutralChip: Color(0xFF242322),
    onNeutralChip: Color(0xFFB5B1AA),
    warmChip: Color(0xFF2C271C),
    onWarmChip: Color(0xFFD6C7A7),
    navBackground: Color(0xFF0A0A0A),
    navSelected: Color(0xFF231E13),
  );

  /// Tema claro: misma identidad (crema + dorado) sobre fondo claro.
  static const light = GavColors(
    background: Color(0xFFF6F4EF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFEBE3),
    border: Color(0xFFE4DFD5),
    text: Color(0xFF141414),
    textMuted: Color(0xFF6B6760),
    textFaint: Color(0xFF9C9891),
    gold: Color(0xFFA98845),
    goldContainer: Color(0xFFF1ECE1),
    goldOnContainer: Color(0xFF8A6D33),
    primaryButton: Color(0xFF141414),
    onPrimaryButton: Color(0xFFF2EFE9),
    success: Color(0xFF1E9E52),
    successContainer: Color(0xFFE3F9EA),
    danger: Color(0xFFD03A32),
    dangerContainer: Color(0xFFFFEAEA),
    neutralChip: Color(0xFFEDEAE4),
    onNeutralChip: Color(0xFF5F5C57),
    warmChip: Color(0xFFF1ECE1),
    onWarmChip: Color(0xFF8A6D33),
    navBackground: Color(0xFFFFFFFF),
    navSelected: Color(0xFFF1ECE1),
  );

  @override
  GavColors copyWith() => this;

  @override
  GavColors lerp(GavColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GavColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      gold: l(gold, other.gold),
      goldContainer: l(goldContainer, other.goldContainer),
      goldOnContainer: l(goldOnContainer, other.goldOnContainer),
      primaryButton: l(primaryButton, other.primaryButton),
      onPrimaryButton: l(onPrimaryButton, other.onPrimaryButton),
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      danger: l(danger, other.danger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      neutralChip: l(neutralChip, other.neutralChip),
      onNeutralChip: l(onNeutralChip, other.onNeutralChip),
      warmChip: l(warmChip, other.warmChip),
      onWarmChip: l(onWarmChip, other.onWarmChip),
      navBackground: l(navBackground, other.navBackground),
      navSelected: l(navSelected, other.navSelected),
    );
  }
}

extension GavThemeX on BuildContext {
  GavColors get gav => Theme.of(this).extension<GavColors>() ?? GavColors.dark;
}
