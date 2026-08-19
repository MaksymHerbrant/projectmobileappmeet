import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dating_app/l10n/gen/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

/// Перший екран застосунку.
///
/// Побудований один в один за макетом `design/Main.dc.html`: розміри, відступи
/// та порядок блоків узяті звідти, а не підібрані на око.
///
/// Замість колажу зі стокових облич — кільця відстані. Це фірмовий мотив
/// продукту: усе тут будується навколо того, хто поруч, і перший екран має це
/// показувати, а не обіцяти обличчями, яких у застосунку ще немає.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  /// Відступ від верху безпечної зони до знака й розмір самого знака.
  /// Кільця беруть центр саме звідси, тому ці числа в одному місці.
  static const double _markTop = 64;
  static const double _markSize = 76;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, _, __) {
        final t = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppTheme.backgroundGradient(context),
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // На низьких екранах (SE) верхній відступ і кегль заголовка
                  // стискаються, інакше нижній текст не влазить.
                  final short = constraints.maxHeight < 700;
                  final markTop = short ? 26.0 : _markTop;
                  final headline = short ? 28.0 : 34.0;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: _DistanceRings(
                          centerY: markTop + _markSize / 2,
                          startRadius: _markSize / 2 + 26,
                        ),
                      ),
                      // Прокрутка як запобіжник: якщо вміст усе одно не влазить
                      // (великий системний шрифт, вузький екран), він
                      // прокручується замість того, щоб обрізатись.
                      SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                              child: Column(
                                children: [
                                  SizedBox(height: markTop),
                                  _Mark(scheme: scheme),
                                  const SizedBox(height: 20),
                                  Text(
                                    t.landing_eyebrow.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 280),
                                    child: Text(
                                      t.landing_headline,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: headline,
                                        height: 1.12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 290),
                                    child: Text(
                                      t.landing_sub,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        height: 1.5,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: short ? 24 : 0),
                                  const Spacer(),
                                  const _SocialRow(),
                                  const SizedBox(height: 12),
                                  const _OrDivider(),
                                  const SizedBox(height: 12),
                                  _PhoneButton(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RegistrationScreen(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _FootNote(
                                    onSignIn: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Концентричні кола, що розходяться від знака.
///
/// Малюються painter-ом, а не набором контейнерів: так крок між кільцями
/// математично однаковий, а їх кількість сама підлаштовується під екран —
/// на маленькому їх менше, на планшеті більше, і жодне не обривається.
class _DistanceRings extends StatelessWidget {
  const _DistanceRings({required this.centerY, required this.startRadius});

  /// Відстань від верху до центру знака.
  final double centerY;

  /// Радіус першого кільця. Відлічується від краю знака, щоб воно його не різало.
  final double startRadius;

  static const double _gap = 74;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: CustomPaint(
          painter: _RingsPainter(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55),
            centerY: centerY,
            startRadius: startRadius,
            gap: _gap,
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({
    required this.color,
    required this.centerY,
    required this.startRadius,
    required this.gap,
  });

  final Color color;
  final double centerY, startRadius, gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;

    final center = Offset(size.width / 2, centerY);

    // Найдальший видимий кут визначає, скільки кілець узагалі має сенс малювати.
    final maxRadius = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - center).distance).reduce((a, b) => a > b ? a : b);

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

class _Mark extends StatelessWidget {
  const _Mark({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      alignment: Alignment.center,
      child: Text(
        'M',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}

/// Google і Apple. Поки що показують пояснення замість дії — кнопка, яка
/// мовчки нічого не робить, гірша за її відсутність.
class _SocialRow extends StatelessWidget {
  const _SocialRow();

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.social_soon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GhostButton(
            onTap: () => _soon(context),
            icon: Image.asset('assets/icons/google.png', width: 20, height: 20),
            label: 'Google',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GhostButton(
            onTap: () => _soon(context),
            icon: Icon(Icons.apple,
                size: 22, color: Theme.of(context).colorScheme.onSurface),
            label: 'Apple',
          ),
        ),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });
  final VoidCallback onTap;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = Expanded(child: Container(height: 1, color: scheme.outlineVariant));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppLocalizations.of(context)!.or_divider,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        line,
      ],
    );
  }
}

class _PhoneButton extends StatelessWidget {
  const _PhoneButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.continue_with_phone,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FootNote extends StatelessWidget {
  const _FootNote({required this.onSignIn});
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final base =
        TextStyle(fontSize: 12, height: 1.5, color: scheme.onSurfaceVariant);
    final link =
        base.copyWith(color: scheme.primary, fontWeight: FontWeight.w600);

    // Порядок слів навколо посилань різний у кожній мові, тому речення
    // збирається з локалізованого шаблону, а не склеюванням шматків.
    const tMark = '@@T@@';
    const pMark = '@@P@@';
    final parts = t
        .terms_line(tMark, pMark)
        .split(RegExp('(?=@@[TP]@@)|(?<=@@[TP]@@)'));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 310),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.have_account, style: base),
              const SizedBox(width: 5),
              GestureDetector(onTap: onSignIn, child: Text(t.login, style: link)),
            ],
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                for (final part in parts)
                  if (part == tMark)
                    TextSpan(text: t.terms, style: link)
                  else if (part == pMark)
                    TextSpan(text: t.privacy_policy, style: link)
                  else
                    TextSpan(text: part, style: base),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
