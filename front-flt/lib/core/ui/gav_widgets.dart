import 'package:material_ui/material_ui.dart';

import '../theme/gav_colors.dart';
import '../theme/gav_theme.dart';

/// Kit de componentes de GAV (hoja "Componentes" de Figma).

// ───────────────────────── Estructura ─────────────────────────

/// Página estándar: fondo, SafeArea, padding lateral 20 y pull-to-refresh opcional.
class GavPage extends StatelessWidget {
  const GavPage({
    super.key,
    required this.children,
    this.onRefresh,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Widget? bottom;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: children,
    );
    return Scaffold(
      backgroundColor: context.gav.background,
      bottomNavigationBar: bottom,
      body: SafeArea(
        bottom: bottom == null,
        child: onRefresh == null
            ? list
            : RefreshIndicator(color: context.gav.gold, onRefresh: onRefresh!, child: list),
      ),
    );
  }
}

/// Top bar de los mockups: eyebrow dorado, título serif, subtítulo, back y acción.
class GavTopBar extends StatelessWidget {
  const GavTopBar({
    super.key,
    required this.title,
    this.eyebrow = 'GAV',
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String eyebrow;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(top: 18, right: 8),
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(20),
                child: Icon(Icons.chevron_left, color: context.gav.text, size: 26),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(), style: GavText.eyebrow(context)),
                const SizedBox(height: 4),
                Text(title, style: GavText.title(context)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: GavText.muted(context)),
                ],
              ],
            ),
          ),
          if (trailing != null) Padding(padding: const EdgeInsets.only(top: 8), child: trailing!),
        ],
      ),
    );
  }
}

class GavSectionTitle extends StatelessWidget {
  const GavSectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(text, style: GavText.strong(context, size: 15))),
            ?trailing,
          ],
        ),
      );
}

class GavCard extends StatelessWidget {
  const GavCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 10),
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: Material(
          color: color ?? context.gav.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.gav.border.withValues(alpha: 0.6)),
              ),
              child: child,
            ),
          ),
        ),
      );
}

// ───────────────────────── Botones ─────────────────────────

/// Botón primario crema ("Iniciar sesión", "Crear cuenta").
class GavPrimaryButton extends StatelessWidget {
  const GavPrimaryButton({super.key, required this.label, this.onPressed, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: g.primaryButton,
          foregroundColor: g.onPrimaryButton,
          disabledBackgroundColor: g.primaryButton.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GavText.strong(context, size: 14.5),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: g.onPrimaryButton),
              )
            : Text(label),
      ),
    );
  }
}

enum GavButtonKind { gold, ghost, goldOutline, dangerOutline }

/// Botones secundarios: dorado ("Aceptar"), fantasma ("Rechazar", "Anterior"),
/// borde dorado ("Editar perfil") y borde rojo ("Cerrar sesión").
class GavButton extends StatelessWidget {
  const GavButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = GavButtonKind.ghost,
    this.icon,
    this.expand = false,
    this.height = 46,
  });

  final String label;
  final VoidCallback? onPressed;
  final GavButtonKind kind;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final (bg, fg, border) = switch (kind) {
      GavButtonKind.gold => (g.gold, const Color(0xFF141414), Colors.transparent),
      GavButtonKind.ghost => (g.surfaceAlt, g.text, g.border),
      GavButtonKind.goldOutline => (Colors.transparent, g.gold, g.gold),
      GavButtonKind.dangerOutline => (Colors.transparent, g.danger, g.border),
    };
    final child = TextButton(
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledForegroundColor: fg.withValues(alpha: 0.4),
        minimumSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
        textStyle: GavText.strong(context, size: 13.5),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Botón ícono circular (campana, refrescar, flechas) y su variante dorada (FAB "+").
class GavIconButton extends StatelessWidget {
  const GavIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.gold = false,
    this.badge = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool gold;
  final bool badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final button = Material(
      color: gold ? g.gold : g.surface,
      shape: gold
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          : const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: gold
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            : const CircleBorder(),
        child: SizedBox.square(
          dimension: 40,
          child: Icon(icon, size: 19, color: gold ? const Color(0xFF141414) : g.text),
        ),
      ),
    );
    return Tooltip(
      message: tooltip ?? '',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          if (badge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: g.gold, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Datos ─────────────────────────

/// Card KPI ("PREDICCIÓN OCT 2027 · 574", "GANANCIA DEL DÍA · $45.000").
class GavKpiCard extends StatelessWidget {
  const GavKpiCard({super.key, required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => GavCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: GavText.label(context), maxLines: 2),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: GavText.kpi(context, color: valueColor)),
            ),
          ],
        ),
      );
}

/// Grilla 2xN de KPIs.
class GavKpiGrid extends StatelessWidget {
  const GavKpiGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: 10),
                Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// Ícono dentro de un cuadro dorado (cards de acceso y notificaciones).
class GavIconBox extends StatelessWidget {
  const GavIconBox({super.key, required this.icon, this.color, this.background, this.size = 40});
  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? context.gav.goldContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: size * 0.48, color: color ?? context.gav.goldOnContainer),
      );
}

/// Card de acceso rápido ("Predicción mensual · Consulta la demanda...").
class GavQuickAccessCard extends StatelessWidget {
  const GavQuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GavCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GavIconBox(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GavText.strong(context, size: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GavText.muted(context, size: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Botón cuadrado de "Más accesos" (ícono dorado + texto).
class GavTileButton extends StatelessWidget {
  const GavTileButton({super.key, required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GavCard(
        onTap: onTap,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: context.gav.gold, size: 20),
            const SizedBox(height: 8),
            Text(label, style: GavText.strong(context, size: 12.5), textAlign: TextAlign.center),
          ],
        ),
      );
}

/// Badge de variación (verde ↑ INCREMENTO / rojo ↓ DECREMENTO).
class GavVariationBadge extends StatelessWidget {
  const GavVariationBadge(this.porcentaje, {super.key});
  final double porcentaje;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final sube = porcentaje >= 0;
    final color = sube ? g.success : g.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: sube ? g.successContainer : g.dangerContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${sube ? '↑' : '↓'} ${formatearPorcentaje(porcentaje)}',
            style: GavText.strong(context, size: 13).copyWith(color: color),
          ),
          Text(
            sube ? 'INCREMENTO' : 'DECREMENTO',
            style: GavText.label(context).copyWith(color: color, fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}

/// Indicador de variación en línea ("↑ +5,8%").
class GavVariationText extends StatelessWidget {
  const GavVariationText(this.porcentaje, {super.key, this.size = 13});
  final double? porcentaje;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = porcentaje;
    if (p == null) return Text('—', style: GavText.muted(context, size: size));
    final color = p >= 0 ? context.gav.success : context.gav.danger;
    return Text(
      '${p >= 0 ? '↑' : '↓'} ${formatearPorcentaje(p)}',
      style: GavText.strong(context, size: size).copyWith(color: color),
    );
  }
}

String formatearPorcentaje(double p) {
  final signo = p >= 0 ? '+' : '−';
  return '$signo${p.abs().toStringAsFixed(1).replaceAll('.', ',')}%';
}

enum GavChipKind { success, danger, neutral, warm, gold }

/// Chip de estado ("FINALIZADO", "BUSCANDO", "CANCELADO", "ACEPTADO").
class GavChip extends StatelessWidget {
  const GavChip(this.text, {super.key, this.kind = GavChipKind.neutral, this.upper = true});
  final String text;
  final GavChipKind kind;
  final bool upper;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final (bg, fg) = switch (kind) {
      GavChipKind.success => (g.successContainer, g.success),
      GavChipKind.danger => (g.dangerContainer, g.danger),
      GavChipKind.neutral => (g.neutralChip, g.onNeutralChip),
      GavChipKind.warm => (g.warmChip, g.onWarmChip),
      GavChipKind.gold => (g.goldContainer, g.gold),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        upper ? text.toUpperCase() : text,
        style: GavText.body(context, size: 10, weight: FontWeight.w700, color: fg)
            .copyWith(letterSpacing: upper ? 0.6 : 0),
      ),
    );
  }
}

/// Avatar con iniciales ("AD", "CP").
class GavAvatar extends StatelessWidget {
  const GavAvatar(this.nombre, {super.key, this.size = 44});
  final String nombre;
  final double size;

  static String iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: context.gav.goldContainer, shape: BoxShape.circle),
        child: Text(
          iniciales(nombre),
          style: GavText.title(context, size: size * 0.36).copyWith(color: context.gav.gold),
        ),
      );
}

// ───────────────────────── Formularios ─────────────────────────

/// Input con etiqueta superior en mayúsculas ("NOMBRE DE USUARIO").
class GavTextField extends StatelessWidget {
  const GavTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.errorText,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
    this.autofillHints,
    this.focusNode,
  });

  final FocusNode? focusNode;
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final String? errorText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final Widget? suffix;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: GavText.label(context)),
            const SizedBox(height: 6),
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscure,
              keyboardType: keyboardType,
              validator: validator,
              textInputAction: textInputAction,
              onFieldSubmitted: onSubmitted,
              autofillHints: autofillHints,
              style: GavText.body(context),
              decoration: InputDecoration(hintText: hint, errorText: errorText, suffixIcon: suffix),
            ),
          ],
        ),
      );
}

/// Selector tipo píldora ("Iniciar sesión | Registrarse", "2026 | 2027",
/// "Conductores | Vehículos | Clientes").
class GavSegmented<T> extends StatelessWidget {
  const GavSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.expand = false,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    final items = options.entries.map((e) {
      final activo = e.key == selected;
      final chip = GestureDetector(
        onTap: () => onChanged(e.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: activo ? g.primaryButton : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            e.value,
            style: GavText.body(
              context,
              size: 13,
              weight: activo ? FontWeight.w700 : FontWeight.w500,
              color: activo ? g.onPrimaryButton : g.textMuted,
            ),
          ),
        ),
      );
      return expand ? Expanded(child: chip) : chip;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: g.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: items),
    );
  }
}

/// Chips de filtro horizontales ("Todos", "Buscando", "Esta semana"...).
class GavFilterChips<T> extends StatelessWidget {
  const GavFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries.map((e) {
          final activo = e.key == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: activo ? g.goldContainer : g.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: activo ? Colors.transparent : g.border),
                ),
                child: Text(
                  e.value,
                  style: GavText.body(
                    context,
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: activo ? g.gold : g.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Fila de preferencia con toggle ("Notificaciones de predicción", "Tema oscuro").
class GavToggleRow extends StatelessWidget {
  const GavToggleRow({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: GavText.body(context, size: 13.5))),
            Transform.scale(scale: 0.85, child: Switch(value: value, onChanged: onChanged)),
          ],
        ),
      );
}

/// Par etiqueta/valor de las cards de perfil ("NOMBRE · Carlos").
class GavInfoItem extends StatelessWidget {
  const GavInfoItem(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: GavText.label(context)),
            const SizedBox(height: 3),
            Text(value.isEmpty ? '—' : value, style: GavText.body(context, size: 13.5)),
          ],
        ),
      );
}

class GavInfo {
  const GavInfo(this.label, this.value, {this.full = false});
  final String label;
  final String value;

  /// Ocupa la fila completa (p. ej. el correo).
  final bool full;
}

/// Grilla de 2 columnas de [GavInfoItem].
class GavInfoGrid extends StatelessWidget {
  const GavInfoGrid({super.key, required this.items});
  final List<GavInfo> items;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var i = 0;
    while (i < items.length) {
      final a = items[i];
      if (a.full || i + 1 >= items.length || items[i + 1].full) {
        rows.add(GavInfoItem(a.label, a.value));
        i++;
      } else {
        final b = items[i + 1];
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: GavInfoItem(a.label, a.value)),
              Expanded(child: GavInfoItem(b.label, b.value)),
            ],
          ),
        );
        i += 2;
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

/// Pie de paginación ("Mostrando 5 de 42 viajes" + Anterior / Siguiente).
class GavPaginationFooter extends StatelessWidget {
  const GavPaginationFooter({super.key, required this.text, this.onPrev, this.onNext});
  final String text;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(child: Text(text, style: GavText.muted(context, size: 11.5))),
            if (onPrev != null || onNext != null) ...[
              GavButton(label: 'Anterior', onPressed: onPrev, height: 38),
              const SizedBox(width: 8),
              GavButton(label: 'Siguiente', onPressed: onNext, height: 38),
            ],
          ],
        ),
      );
}

/// Card de notificación (ícono, título, descripción, tiempo y punto de no leída).
class GavNotificationCard extends StatelessWidget {
  const GavNotificationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    this.unread = false,
    this.iconColor,
    this.iconBackground,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String time;
  final bool unread;
  final Color? iconColor;
  final Color? iconBackground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GavCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GavIconBox(icon: icon, color: iconColor, background: iconBackground, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GavText.strong(context, size: 13.5)),
                  const SizedBox(height: 3),
                  Text(description, style: GavText.muted(context, size: 12)),
                  const SizedBox(height: 6),
                  Text(time, style: GavText.body(context, size: 10.5, color: context.gav.textFaint)),
                ],
              ),
            ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: context.gav.gold, shape: BoxShape.circle),
              ),
          ],
        ),
      );
}

// ───────────────────────── Barra inferior ─────────────────────────

class GavNavItem {
  const GavNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Barra inferior con píldora dorada en el ítem activo.
class GavBottomNav extends StatelessWidget {
  const GavBottomNav({super.key, required this.items, required this.index, required this.onTap});
  final List<GavNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.gav;
    return Container(
      decoration: BoxDecoration(
        color: g.navBackground,
        border: Border(top: BorderSide(color: g.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(items.length, (i) {
              final activo = i == index;
              final it = items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: activo ? g.navSelected : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(it.icon, size: 20, color: activo ? g.gold : g.textMuted),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        it.label,
                        style: GavText.body(
                          context,
                          size: 10.5,
                          weight: activo ? FontWeight.w700 : FontWeight.w500,
                          color: activo ? g.gold : g.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
