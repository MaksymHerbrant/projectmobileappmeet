import 'dart:math' as math;

import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Будівельні блоки макета.
///
/// Кожен віджет тут — це один клас зі стилів `design/*.dc.html`. Числа взяті
/// звідти дослівно й живуть тільки в цьому файлі: екрани складаються з готових
/// блоків і не містять власних розмірів, тож «за макетом» виходить за
/// побудовою, а не за уважністю під час переписування.
///
/// Кольори не вписані. Палітра макета збігається з `AppTheme` токен у токен
/// (перевірено звіркою всіх значень обох тем), тому `--pri` це
/// `colorScheme.primary`, `--out` це `outlineVariant`, `--ok`/`--warn` —
/// `AppSemantics`. Через це темна тема працює без окремої гілки.
class Ds {
  const Ds._();

  // Радіуси з макета
  static const double rButton = 16;
  static const double rField = 14;
  static const double rCard = 16;
  static const double rTile = 14;

  static const double hControl = 52; // .btn, .field
  static const double hChip = 34; // .chip
  static const double hNav = 78; // .nav

  /// Горизонтальні поля екрана (.pad)
  static const EdgeInsets pad = EdgeInsets.symmetric(horizontal: 20);

  /// `--sh`: підкладка карток і плаваючих кнопок.
  static List<BoxShadow> shadow(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const [
            BoxShadow(
                color: Color(0x59000000), blurRadius: 2, offset: Offset(0, 1)),
            BoxShadow(
                color: Color(0x4D000000), blurRadius: 24, offset: Offset(0, 8)),
          ]
        : const [
            BoxShadow(
                color: Color(0x0D191C20), blurRadius: 2, offset: Offset(0, 1)),
            BoxShadow(
                color: Color(0x12191C20), blurRadius: 24, offset: Offset(0, 8)),
          ];
  }

  /// Фон екрана: градієнт `--g1 → --g2`.
  static BoxDecoration background(BuildContext context) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.backgroundGradient(context),
        ),
      );

  // ------------------------------------------------------------------ текст

  static TextStyle h1(BuildContext context) => TextStyle(
        fontSize: 27,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: context.scheme.onSurface,
      );

  static TextStyle h2(BuildContext context) => TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: context.scheme.onSurface,
      );

  static TextStyle sub(BuildContext context) => TextStyle(
        fontSize: 14.5,
        height: 1.5,
        color: context.scheme.onSurfaceVariant,
      );

  static TextStyle tiny(BuildContext context) => TextStyle(
        fontSize: 12,
        height: 1.5,
        color: context.scheme.onSurfaceVariant,
      );

  static TextStyle label(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: context.scheme.onSurfaceVariant,
      );

  static TextStyle body(BuildContext context) => TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        color: context.scheme.onSurface,
      );
}

/// Корінь екрана: градієнт, безпечна зона і захист від обрізання.
///
/// Прокрутка тут не декоративна. Макет намальовано під 390×844; на 320×568
/// або зі збільшеним системним шрифтом вміст не влазить, і без цього він
/// обрізався б мовчки — на реальному телефоні це помітно вже на першому кроці.
///
/// На широких екранах (планшет, веб) колонка вмісту обмежена: поле вводу на
/// всю ширину монітора виглядає зламаним, а макет малювався під телефон.
class DsScreen extends StatelessWidget {
  final Widget child;

  /// Верхній рядок (`.top`) малюється поза прокруткою, щоб кнопка «назад»
  /// лишалась на місці.
  final Widget? top;
  final Widget? bottom;

  const DsScreen({super.key, required this.child, this.top, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: Ds.background(context),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  if (top != null) top!,
                  Expanded(child: child),
                  if (bottom != null) bottom!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.top` — кнопка назад, розпірка, підпис кроку.
///
/// У макеті відступ 56px рахується від краю кадру, тобто разом зі статусним
/// рядком. Тут статусний рядок уже з'їдено SafeArea, тому віднімаємо його —
/// інакше на телефонах із високим вирізом шапка з'їжджає вниз.
class DsTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final String? trailingText;
  final Widget? trailing;

  /// Заголовок поруч із кнопкою «назад» — як на екрані налаштувань.
  final String? title;

  const DsTopBar({
    super.key,
    this.onBack,
    this.trailingText,
    this.trailing,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    final top = math.max(56 - inset, 8.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, top, 20, 14),
      child: Row(
        children: [
          if (onBack != null)
            DsIconButton(
              icon: Icons.chevron_left_rounded,
              onTap: onBack,
              semanticLabel:
                  MaterialLocalizations.of(context).backButtonTooltip,
            ),
          const Spacer(),
          if (trailing != null)
            trailing!
          else if (trailingText != null)
            Text(trailingText!, style: Ds.tiny(context)),
        ],
      ),
    );
  }
}

/// `.iconbtn` — 44×44, радіус 14, на поверхні з тінню.
class DsIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const DsIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(Ds.rTile),
        child: InkWell(
          borderRadius: BorderRadius.circular(Ds.rTile),
          onTap: onTap,
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(Ds.rTile),
              boxShadow: Ds.shadow(context),
            ),
            child: Icon(icon, size: 22, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// `.bar` — смужка прогресу кроків, висота 4.
class DsProgressBar extends StatelessWidget {
  /// Від 0 до 1.
  final double value;

  const DsProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Semantics(
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: 4,
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: scheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation(scheme.primary),
          ),
        ),
      ),
    );
  }
}

/// `.card` — поверхня, радіус 16, тінь `--sh`.
class DsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const DsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: BorderRadius.circular(Ds.rCard),
        boxShadow: Ds.shadow(context),
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Ds.rCard),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// `.btn` — головна дія: висота 52, радіус 16.
///
/// `ghost` — варіант із рамкою замість заливки.
class DsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool ghost;
  final bool loading;
  final IconData? icon;
  final Widget? leading;

  const DsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.ghost = false,
    this.loading = false,
    this.icon,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final disabled = onPressed == null || loading;
    final fg = ghost ? scheme.primary : scheme.onPrimary;

    return Opacity(
      opacity: disabled && !loading ? 0.45 : 1,
      child: Material(
        color: ghost ? Colors.transparent : scheme.primary,
        borderRadius: BorderRadius.circular(Ds.rButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(Ds.rButton),
          onTap: disabled ? null : onPressed,
          child: Container(
            height: Ds.hControl,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Ds.rButton),
              border: ghost
                  ? Border.all(color: scheme.outlineVariant, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 8)
                      ],
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// `.field` як контейнер: висота 52, радіус 14, рамка `--out`,
/// а в фокусі — `--pri` завтовшки 1.5, як у макеті.
class DsFieldBox extends StatelessWidget {
  final Widget child;
  final bool focused;
  final bool error;
  final double? width;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  const DsFieldBox({
    super.key,
    required this.child,
    this.focused = false,
    this.error = false,
    this.width,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final color = error
        ? scheme.error
        : focused
            ? scheme.primary
            : scheme.outlineVariant;

    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: width,
      height: Ds.hControl,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(Ds.rField),
        border: Border.all(color: color, width: focused || error ? 1.5 : 1),
      ),
      child: child,
    );

    if (onTap == null) return box;
    return GestureDetector(
        onTap: onTap, behavior: HitTestBehavior.opaque, child: box);
  }
}

/// Поле вводу в оформленні `.field`.
///
/// Рамку малює контейнер, а не `InputDecoration`: так висота та радіус
/// збігаються з макетом і не залежать від того, чи є підказка й лічильник.
class DsTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? prefix;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool enabled;
  final bool autofocus;
  final int? maxLength;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final Widget? suffix;
  final bool error;

  const DsTextField({
    super.key,
    this.controller,
    this.hint,
    this.prefix,
    this.icon,
    this.keyboardType,
    this.obscure = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
    this.focusNode,
    this.suffix,
    this.error = false,
  });

  @override
  State<DsTextField> createState() => _DsTextFieldState();
}

class _DsTextFieldState extends State<DsTextField> {
  late final FocusNode _node = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (_node.hasFocus != _focused) setState(() => _focused = _node.hasFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return DsFieldBox(
      focused: _focused,
      error: widget.error,
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
          ],
          if (widget.prefix != null) ...[
            Text(
              widget.prefix!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _node,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              textCapitalization: widget.capitalization,
              onChanged: widget.onChanged,
              style: TextStyle(fontSize: 16, color: scheme.onSurface),
              cursorColor: scheme.primary,
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hint,
                hintStyle:
                    TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          if (widget.suffix != null) widget.suffix!,
        ],
      ),
    );
  }
}

/// `.chip` — обраний стан заливає `--pri`, як у макеті.
class DsChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool small;
  final IconData? icon;
  final VoidCallback? onTap;

  const DsChip({
    super.key,
    required this.label,
    this.selected = false,
    this.small = false,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final bg = selected ? scheme.primary : scheme.secondaryContainer;
    final fg = selected ? scheme.onPrimary : scheme.onSecondaryContainer;

    return Semantics(
      selected: selected,
      button: onTap != null,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: small ? 28 : Ds.hChip,
            padding: EdgeInsets.symmetric(horizontal: small ? 11 : 14),
            child: Row(
              // min — інакше Container з alignment у Wrap чи Positioned
              // розтягнувся б на всю доступну ширину.
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: small ? 13 : 15, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: small ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.ph-block` — підкладка під фото: діагональний градієнт із відблиском.
/// Використовується і як заглушка, і як тло, доки фото вантажиться.
class DsPhotoBlock extends StatelessWidget {
  final String? initial;
  final double radius;
  final double fontSize;
  final Widget? child;

  const DsPhotoBlock({
    super.key,
    this.initial,
    this.radius = Ds.rField,
    this.fontSize = 26,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHighest,
            scheme.surfaceContainerHigh,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: child ??
          (initial == null || initial!.isEmpty
              ? null
              : Text(
                  // Перша літера, а не весь рядок: сюди передають повну назву.
                  initial!.characters.first.toUpperCase(),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
                )),
    );
  }
}

/// Порожня комірка з пунктиром і плюсом — «додати фото».
class DsAddTile extends StatelessWidget {
  final VoidCallback? onTap;
  final double radius;

  const DsAddTile({super.key, this.onTap, this.radius = Ds.rField});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter:
            _DashedBorderPainter(color: scheme.outlineVariant, radius: radius),
        child: Center(
          child:
              Icon(Icons.add_rounded, size: 20, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// `1.5px dashed` з макета. У Flutter немає пунктирної рамки, тож малюємо її.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));

    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// `.av` — кружок з ініціалом.
class DsAvatar extends StatelessWidget {
  final String? initial;
  final String? photoUrl;
  final double size;

  const DsAvatar({super.key, this.initial, this.photoUrl, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Мережа підводить частіше за все інше — падати на текстову
          // заглушку тут обов'язково, інакше в списку буде порожня діра.
          errorBuilder: (_, __, ___) => _fallback(scheme),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _fallback(scheme),
        ),
      );
    }
    return _fallback(scheme);
  }

  Widget _fallback(ColorScheme scheme) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          (initial ?? '?').characters.take(1).toString().toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: scheme.onPrimaryContainer,
          ),
        ),
      );
}

/// `.seg` — перемикач із двох-трьох варіантів.
class DsSegmented extends StatelessWidget {
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;

  const DsSegmented({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Ds.rField),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? scheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: i == index ? Ds.shadow(context) : null,
                  ),
                  child: Text(
                    items[i],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: i == index
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.dist` — напівпрозора плашка з відстанню поверх фото.
class DsPill extends StatelessWidget {
  final String label;
  final IconData? icon;

  const DsPill({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x6B000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Рядок «галочка + текст» зі списків переваг.
class DsCheckLine extends StatelessWidget {
  final String text;

  const DsCheckLine({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_rounded, size: 20, color: context.semantics.success),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Ds.sub(context).copyWith(color: context.scheme.onSurface),
          ),
        ),
      ],
    );
  }
}

/// Рядок «іконка + дрібний текст» — примітки про приватність.
class DsNote extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? iconColor;

  const DsNote({
    super.key,
    required this.text,
    this.icon = Icons.shield_outlined,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Ds.tiny(context))),
      ],
    );
  }
}

/// Кільця відстані — фірмовий мотив.
///
/// Радіуси йдуть із однаковим кроком від заданого центру, а їх кількість
/// рахується від найдальшого кута екрана: на маленькому екрані їх менше, на
/// планшеті більше, і жодне не обривається на півдорозі.
class DsRings extends StatelessWidget {
  final double centerY;
  final double startRadius;
  final double gap;
  final double opacity;

  const DsRings({
    super.key,
    required this.centerY,
    required this.startRadius,
    this.gap = 74,
    this.opacity = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RingsPainter(
          color: context.scheme.outlineVariant.withValues(alpha: opacity),
          centerY: centerY,
          startRadius: startRadius,
          gap: gap,
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final Color color;
  final double centerY;
  final double startRadius;
  final double gap;

  const _RingsPainter({
    required this.color,
    required this.centerY,
    required this.startRadius,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, centerY);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final maxRadius =
        corners.map((c) => (c - center).distance).reduce(math.max);

    for (var r = startRadius; r <= maxRadius; r += gap) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.color != color ||
      old.centerY != centerY ||
      old.startRadius != startRadius ||
      old.gap != gap;
}

/// Google і Apple поруч — один рядок із макетів `Main` і `Login`.
///
/// Поки що показують пояснення замість дії: кнопка, яка мовчки нічого не
/// робить, гірша за її відсутність.
class DsSocialRow extends StatelessWidget {
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  const DsSocialRow({super.key, this.onGoogle, this.onApple});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DsButton(
            ghost: true,
            label: 'Google',
            onPressed: onGoogle ?? () => _soon(context),
            leading: Image.asset(
              'assets/icons/google.png',
              width: 20,
              height: 20,
              // Іконка лежить в ассетах, але якщо її колись переміщують,
              // краще показати запасну, ніж червоний прямокутник помилки.
              errorBuilder: (_, __, ___) => Icon(
                Icons.g_mobiledata_rounded,
                size: 22,
                color: context.scheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DsButton(
            ghost: true,
            label: 'Apple',
            onPressed: onApple ?? () => _soon(context),
            leading:
                Icon(Icons.apple, size: 22, color: context.scheme.onSurface),
          ),
        ),
      ],
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.social_soon)),
    );
  }
}

/// Роздільник «— або —» з макета.
class DsOrDivider extends StatelessWidget {
  final String label;

  const DsOrDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: context.scheme.outlineVariant),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: Ds.tiny(context)),
        ),
        line,
      ],
    );
  }
}

/// Один пункт нижньої навігації.
class DsNavItem {
  final IconData icon;
  final String label;

  const DsNavItem({required this.icon, required this.label});
}

/// `.nav` — нижня навігація.
///
/// Активний пункт позначається плашкою `--pri-c`, а не кольором іконки: на
/// темній темі перефарбована іконка майже не читалась.
///
/// Висота 78 у макеті виміряна без смуги-«домівки». Тут до неї додається
/// системний нижній відступ, інакше на телефонах без кнопки нижній ряд
/// опиняється під смугою.
class DsNavBar extends StatelessWidget {
  final List<DsNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  const DsNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final inset = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: Ds.hNav + inset,
      padding: EdgeInsets.only(bottom: inset),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            Semantics(
              selected: i == index,
              button: true,
              label: items[i].label,
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  height: 44,
                  decoration: BoxDecoration(
                    color: i == index
                        ? scheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(Ds.rTile),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    items[i].icon,
                    size: 22,
                    color: i == index
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Рядок пошуку з макетів стрічки й чатів: висота 46, повністю скруглений.
class DsSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const DsSearchField(
      {super.key, required this.hint, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontSize: 15, color: scheme.onSurface),
              cursorColor: scheme.primary,
              decoration: InputDecoration(
                isDense: true,
                // Рамку малює контейнер. `border` сам по собі не допомагає:
                // глобальна тема задає enabledBorder і focusedBorder окремо,
                // і саме вони проступали другим контуром усередині пігулки.
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle:
                    TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Повзунок радіуса пошуку — шпилька, підпис і смуга з макета стрічки.
class DsRadiusSlider extends StatelessWidget {
  final int km;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String Function(int km) format;

  const DsRadiusSlider({
    super.key,
    required this.km,
    required this.onChanged,
    required this.format,
    this.min = 1,
    this.max = 100,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Row(
      children: [
        Icon(Icons.place_outlined, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            format(km),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.outlineVariant,
              thumbColor: scheme.primary,
              overlayColor: scheme.primary.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: km.toDouble().clamp(min.toDouble(), max.toDouble()),
              min: min.toDouble(),
              max: max.toDouble(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
      ],
    );
  }
}

/// Нижня смуга з головною дією.
///
/// У макеті кнопка — останній елемент колонки на кадрі 844px заввишки, тож
/// вона там завжди видима. На 320×568 того запасу немає, і всередині
/// прокрутки кнопка йде за межі екрана. Тому вона живе поза прокруткою:
/// форма гортається, дія лишається на місці.
class DsActionBar extends StatelessWidget {
  final Widget child;

  const DsActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      // 36 з макета; на телефонах зі смугою-«домівкою» вистачає меншого
      // відступу, бо саму смугу вже враховано.
      padding: EdgeInsets.fromLTRB(20, 12, 20, inset > 0 ? 12 + inset : 36),
      child: child,
    );
  }
}

/// Розділ налаштувань за `design/Settings.dc.html`: підпис над карткою,
/// а всередині — рядки, розділені лінією з відступом під іконку.
class DsSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const DsSection({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(title.toUpperCase(), style: Ds.label(context)),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.scheme.surface,
            borderRadius: BorderRadius.circular(Ds.rCard),
            boxShadow: Ds.shadow(context),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Padding(
                    // Лінія починається під текстом, а не під іконкою — так
                    // рядки читаються як список, а не як таблиця.
                    padding: const EdgeInsets.only(left: 32),
                    child: Divider(height: 1, color: context.scheme.outlineVariant),
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Рядок усередині `DsSection`.
class DsRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;
  final bool destructive;
  final Widget? trailing;

  /// Рядки-варіанти (мова, тема) стрілку не показують: вона означає
  /// «відкриється екран», а тут вибір робиться на місці.
  final bool chevron;

  const DsRow({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    this.onTap,
    this.selected = false,
    this.destructive = false,
    this.trailing,
    this.chevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final accent = destructive
        ? scheme.error
        : selected
            ? scheme.primary
            : scheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: icon == null
                  ? null
                  : Icon(
                      icon,
                      size: 20,
                      color: destructive
                          ? scheme.error
                          : selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: accent,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: Ds.tiny(context)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (selected)
              Icon(Icons.check_rounded, size: 20, color: scheme.primary)
            else if (onTap != null && chevron)
              Icon(Icons.chevron_right_rounded, size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Порожній стан за `design/FeedEmpty.dc.html`: кільця, кружок з іконкою,
/// заголовок, пояснення, головна дія і тихий другий варіант.
class DsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? footer;

  const DsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: DsRings(
                centerY: constraints.maxHeight / 2 - 40,
                startRadius: 95,
                gap: 55,
                opacity: 0.45,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: Ds.shadow(context),
                      ),
                      child: Icon(icon, size: 30, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    Text(title, textAlign: TextAlign.center, style: Ds.h2(context)),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Text(body, textAlign: TextAlign.center, style: Ds.sub(context)),
                    ),
                    if (actionLabel != null) ...[
                      const SizedBox(height: 18),
                      DsButton(label: actionLabel!, onPressed: onAction),
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: 12),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
