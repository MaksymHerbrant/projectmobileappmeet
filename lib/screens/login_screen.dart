import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../service/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_kit.dart';
import 'forgot_password_screen.dart';
import 'main_navigation_screen.dart';

/// Вхід.
///
/// Оформлення з `design/Login.dc.html`: соцкнопки першими, роздільник,
/// потім номер і пароль. Порядок не випадковий — попередження про другий
/// профіль має сенс лише тоді, коли обидва способи видно поруч.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final t = AppLocalizations.of(context)!;

    // Проста валідація
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.enter_valid_email)));
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.enter_password)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 👇 Викликаємо вхід за паролем
      await _authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        // Успішний вхід -> Головний екран
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Показуємо помилку (наприклад, невірний пароль)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.wrong_phone_or_password),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final t = AppLocalizations.of(context)!;

        return DsScreen(
          top: DsTopBar(onBack: () => Navigator.pop(context)),
          bottom: DsActionBar(
            child: DsButton(
              label: t.enter,
              loading: _isLoading,
              onPressed: _isLoading ? null : _handleLogin,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: Ds.pad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Text(t.login_title, style: Ds.h1(context)),
                  const SizedBox(height: 10),
                  Text(t.login_sub, style: Ds.sub(context)),
                  const SizedBox(height: 28),
                  const DsSocialRow(),
                  const SizedBox(height: 14),
                  DsOrDivider(label: t.or_by_email),
                  const SizedBox(height: 14),
                  Text(t.email_label.toUpperCase(), style: Ds.label(context)),
                  const SizedBox(height: 8),
                  DsTextField(
                    controller: _emailController,
                    icon: Icons.mail_outline_rounded,
                    hint: 'maks@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 12),
                  Text(t.password.toUpperCase(), style: Ds.label(context)),
                  const SizedBox(height: 8),
                  DsTextField(
                    controller: _passwordController,
                    obscure: !_isPasswordVisible,
                    hint: '••••••••',
                    enabled: !_isLoading,
                    suffix: GestureDetector(
                      onTap: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                      child: Text(
                        _isPasswordVisible ? t.hide_password : t.show_password,
                        style: Ds.tiny(context).copyWith(
                          color: context.scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      ),
                      child: Text(
                        t.forgot_password,
                        style: Ds.tiny(context)
                            .copyWith(color: context.scheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
