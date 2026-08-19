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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Column(
                      children: [
                        const SizedBox(height: 64),
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
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(
                            t.landing_headline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 290),
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
                        const Spacer(),
                        const _SocialRow(),
                        const SizedBox(height: 12),
                        const _OrDivider(),
                        const SizedBox(height: 12),
                        _PhoneButton(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegistrationScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FootNote(
                          onSignIn: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                        ),
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

/// Концентричні кола: «радіус пошуку» як графіка.
///
/// Діаметри й зсув центру взяті з макета (280/430/580/730 при центрі трохи
/// вище середини екрана).
class _DistanceRings extends StatelessWidget {
  const _DistanceRings();

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;
    return IgnorePointer(
      // Без обрізання кільце в 880px розсуває сторінку вшир, і решта екрана
      // з'їжджає за правий край.
      child: ClipRect(
        child: Align(
        alignment: const Alignment(0, -0.05),
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final d in const [280.0, 430.0, 580.0, 730.0, 880.0])
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
