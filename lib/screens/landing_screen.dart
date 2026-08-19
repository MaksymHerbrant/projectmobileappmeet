import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dating_app/l10n/gen/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

/// Перший екран застосунку.
///
/// Замість колажу зі стокових облич — кільця відстані. Це фірмовий мотив
/// продукту: усе тут будується навколо того, хто поруч, і перший екран має це
/// показувати, а не обіцяти обличчями, яких у застосунку ще немає.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

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
            child: Stack(
              children: [
                const Positioned.fill(child: _DistanceRings()),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        _Mark(scheme: scheme),
                        const SizedBox(height: 22),
                        Text(
                          t.landing_eyebrow.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          t.landing_headline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
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
                        const Spacer(flex: 3),
                        _PrimaryButton(
                          label: t.lets_start,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegistrationScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SignInLine(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _TermsLine(),
                        const SizedBox(height: 26),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Концентричні кола від центру логотипа: «радіус пошуку» як графіка.
class _DistanceRings extends StatelessWidget {
  const _DistanceRings();

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.42),
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final d in const [300.0, 460.0, 620.0, 790.0])
              Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: line.withValues(alpha: 0.55)),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.32),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
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
            Text(label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 15),
          ],
        ),
      ),
    );
  }
}

class _SignInLine extends StatelessWidget {
  const _SignInLine({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(t.have_account,
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onTap,
          child: Text(
            t.login,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsLine extends StatelessWidget {
  const _TermsLine();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final base =
        TextStyle(fontSize: 11.5, height: 1.5, color: scheme.onSurfaceVariant);
    final link =
        base.copyWith(color: scheme.primary, fontWeight: FontWeight.w600);

    // Порядок слів у реченні різний у кожній мові, тому речення збирається з
    // локалізованого шаблону, а не склеюванням шматків.
    const tMark = '@@T@@';
    const pMark = '@@P@@';
    final parts = t
        .terms_line(tMark, pMark)
        .split(RegExp('(?=@@[TP]@@)|(?<=@@[TP]@@)'));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Text.rich(
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
    );
  }
}
