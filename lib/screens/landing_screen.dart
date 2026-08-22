import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dating_app/l10n/gen/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../theme/design_kit.dart';
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

  /// Відступ від верху кадру до знака й розмір самого знака — з Main.dc.html
  /// (`padding-top:104`). У макеті відступ рахується разом зі статусним
  /// рядком, тому в build від нього віднімається верхній inset.
  /// Кільця беруть центр саме звідси, тому ці числа в одному місці.
  static const double _markTop = 104;
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
                  final inset = MediaQuery.paddingOf(context).top;
                  final short = constraints.maxHeight < 700;
                  final markTop =
                      short ? 26.0 : (_markTop - inset).clamp(40.0, _markTop);
                  final headline = short ? 28.0 : 34.0;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: DsRings(
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
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                              child: Column(
                                children: [
                                  SizedBox(height: markTop),
                                  _Mark(scheme: scheme),
                                  const SizedBox(height: 32),
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
                                  const DsSocialRow(),
                                  const SizedBox(height: 12),
                                  DsOrDivider(label: t.or_divider),
                                  const SizedBox(height: 12),
                                  DsButton(
                                    label: t.continue_with_email,
                                    icon: Icons.mail_outline_rounded,
                                    onPressed: () => Navigator.of(context).push(
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
    final parts =
        t.terms_line(tMark, pMark).split(RegExp('(?=@@[TP]@@)|(?<=@@[TP]@@)'));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 310),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.have_account, style: base),
              const SizedBox(width: 5),
              GestureDetector(
                  onTap: onSignIn, child: Text(t.login, style: link)),
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
