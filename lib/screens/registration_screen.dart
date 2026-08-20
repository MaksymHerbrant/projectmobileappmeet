import 'dart:async';

import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../service/auth_service.dart';
import '../service/error_reporter.dart';
import '../theme/app_theme.dart';
import '../theme/design_kit.dart';
import 'main_navigation_screen.dart';

/// Реєстрація.
///
/// Оформлення взяте з `design/Phone.dc.html`, `Code.dc.html` і `About.dc.html`:
/// шапка з кнопкою назад і лічильником кроків, смужка прогресу, заголовок,
/// підзаголовок, вміст, кнопка внизу. Усі розміри приходять із `Ds`.
///
/// Логіка кроків не змінена. У макеті кроків теж п'ять, але інших — пароля там
/// немає, зате є фото й інтереси. Тут збережено наявний порядок, а вигляд
/// приведено до макета.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const int _stepCount = 4;

  /// Скільки секунд чекати до повторного листа.
  static const int _resendSeconds = 60;

  /// Довжина коду з листа. Має збігатися з «Email OTP Length» у Supabase.
  static const int _codeLength = 6;

  final _authService = AuthService();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  final TextEditingController _smsController = TextEditingController();
  final FocusNode _smsFocusNode = FocusNode();

  DateTime? _selectedDate;

  Timer? _resendTimer;
  int _resendLeft = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _birthdayController.dispose();
    _smsController.dispose();
    _smsFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- ГОЛОВНА ЛОГІКА ПЕРЕВІРКИ ТА ПЕРЕХОДУ ---

  Future<void> _handleNext() async {
    // 1. Примусово ховаємо клавіатуру перед будь-якою дією
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      if (_currentStep == 0) {
        // КРОК 1: ПОШТА + ПАРОЛЬ — лише перевірки, у базу ще нічого не йде.
        final email = _emailController.text.trim();
        if (!email.contains('@') || !email.contains('.')) {
          throw Exception(AppLocalizations.of(context)!.enter_valid_email);
        }
        if (_passwordController.text.length < 6) {
          throw Exception(AppLocalizations.of(context)!.rg_password_short);
        }

        // Пошта вже зареєстрована (і підтверджена) → пропонуємо вхід.
        final bool exists = await _authService.checkEmailRegistered(email);
        if (exists) {
          setState(() => _isLoading = false);
          _showUserExistsDialog();
          return;
        }
        _goToNextPage();
      } else if (_currentStep == 1) {
        // КРОК 2: ІМ'Я — локально.
        if (_nameController.text.trim().isEmpty)
          throw const AppFailure(FailureKind.save);
        _goToNextPage();
      } else if (_currentStep == 2) {
        // КРОК 3: ДАТА — локально; лише тепер шлемо код.
        if (_selectedDate == null) {
          throw Exception(AppLocalizations.of(context)!.rg_need_birth);
        }
        await _authService.sendEmailCode(_emailController.text.trim());
        _startResendCountdown();
        _goToNextPage();

        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _smsFocusNode.requestFocus();
        });
      } else if (_currentStep == 3) {
        // КРОК 4 (останній): КОД. Підтвердження і створення анкети — одна
        // дія, тож покинута реєстрація не лишає в базі нічого, крім
        // непідтвердженого запису auth, який не блокує адресу й не видний
        // у стрічці.
        if (_smsController.text.length < _codeLength) {
          throw Exception(AppLocalizations.of(context)!.rg_code_incomplete);
        }
        await _authService.verifyEmailCode(
            _emailController.text, _smsController.text);
        await _completeRegistration();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorText(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Відлік до повторного SMS. Макет показує його на кроці коду, і без
  /// справжнього таймера цей рядок був би просто намальованим текстом.
  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendLeft = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendLeft--);
      if (_resendLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resendCode() async {
    try {
      await _authService.sendEmailCode(_emailController.text.trim());
      _startResendCountdown();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorText(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Людський текст помилки. Валідація кидає Exception із готовим перекладом,
  /// сервіси — AppFailure з кодом; сирий toString не показуємо ніколи.
  String _errorText(Object e) {
    if (e is AppFailure) return e.localized(context);
    if (e is Exception) {
      final raw = e.toString().replaceFirst('Exception:', '').trim();
      // Повідомлення власної валідації — вже перекладені й короткі.
      if (!raw.contains('Exception') && raw.length < 120) return raw;
    }
    return ErrorReporter.message(context, e);
  }

  void _showUserExistsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.account_exists_title),
        content: Text(AppLocalizations.of(context)!.account_exists_email_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.change_email),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Закрити діалог
              Navigator.pop(context); // Повернутися на екран входу (Login)
            },
            child: Text(AppLocalizations.of(context)!.login),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRegistration() async {
    await _authService.completeRegistration(
      name: _nameController.text,
      birthDate: _selectedDate!,
      password: _passwordController.text,
    );
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  void _goToNextPage() {
    setState(() => _currentStep++);
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep--);
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // --- UI БУДІВНИЦТВО ---

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return DsScreen(
      bottom: DsActionBar(
        child: DsButton(
          label: _actionLabel(t),
          loading: _isLoading,
          onPressed: _isLoading ? null : _handleNext,
        ),
      ),
      top: DsTopBar(
        onBack: _isLoading
            ? null
            : (_currentStep > 0 ? _previousStep : () => Navigator.pop(context)),
        trailingText: t.step_of(_currentStep + 1, _stepCount),
      ),
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _step(
            title: t.rg_email_title,
            subtitle: t.rg_email_sub,
            content: _emailStep(t),
          ),
          _step(
            title: t.rg_about_title,
            subtitle: t.rg_about_sub,
            content: _nameStep(t),
          ),
          _step(
            title: t.rg_age,
            subtitle: t.rg_adults_only,
            content: _birthdayStep(t),
          ),
          _step(
            title: t.rg_email_code_title,
            subtitle: null,
            subtitleWidget: _sentToLine(t),
            content: _smsStep(t),
          ),
        ],
      ),
    );
  }

  /// Каркас кроку з `design/*.dc.html`: смужка, заголовок, підзаголовок,
  /// вміст, розпірка, кнопка.
  ///
  /// Вміст у прокрутці навмисно: коли з'являється клавіатура, вільного місця
  /// лишається сотня-друга пікселів, і без цього поле з підказкою обрізалося б.
  /// Підпис головної кнопки залежить від кроку.
  String _actionLabel(AppLocalizations t) => switch (_currentStep) {
        3 => t.rg_confirm,
        _ => t.rg_next,
      };

  Widget _step({
    required String title,
    required String? subtitle,
    required Widget content,
    Widget? subtitleWidget,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: Ds.pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DsProgressBar(value: (_currentStep + 1) / _stepCount),
            const SizedBox(height: 28),
            Text(title, style: Ds.h1(context)),
            const SizedBox(height: 10),
            if (subtitleWidget != null)
              subtitleWidget
            else if (subtitle != null)
              Text(subtitle, style: Ds.sub(context)),
            const SizedBox(height: 26),
            content,
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- крок 1: пошта

  Widget _emailStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.email_label.toUpperCase(), style: Ds.label(context)),
        const SizedBox(height: 8),
        DsTextField(
          controller: _emailController,
          hint: 'maks@gmail.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          autofocus: true,
        ),
        const SizedBox(height: 14),
        Text(t.password.toUpperCase(), style: Ds.label(context)),
        const SizedBox(height: 8),
        DsTextField(
          controller: _passwordController,
          hint: t.rg_password_hint,
          obscure: !_isPasswordVisible,
          enabled: !_isLoading,
          suffix: GestureDetector(
            onTap: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
            child: Text(
              _isPasswordVisible ? t.hide_password : t.show_password,
              style: Ds.tiny(context).copyWith(
                color: context.scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DsNote(text: t.rg_email_note),
      ],
    );
  }

  // --------------------------------------------------------------- крок 2: код

  Widget _sentToLine(AppLocalizations t) {
    // Номер виділено, як у макеті. Збирати рядок конкатенацією не можна —
    // у різних мовах номер стоїть у різних місцях, тож ріжемо готовий переклад.
    final email = _emailController.text.trim();
    final full = t.rg_sms_sent_to(email);
    final at = full.indexOf(email);

    if (at < 0) return Text(full, style: Ds.sub(context));

    return Text.rich(
      TextSpan(
        style: Ds.sub(context),
        children: [
          TextSpan(text: full.substring(0, at)),
          TextSpan(
            text: email,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.scheme.onSurface,
            ),
          ),
          TextSpan(text: full.substring(at + email.length)),
        ],
      ),
    );
  }

  Widget _smsStep(AppLocalizations t) {
    final left = Duration(seconds: _resendLeft);
    final clock =
        '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _smsFocusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Макет малює комірки по 48 з проміжком 8. На вузькому екрані
              // шість таких у рядок не вміщаються, тож комірка стискається.
              const gap = 8.0;
              final cell = ((constraints.maxWidth - gap * (_codeLength - 1)) /
                      _codeLength)
                  .clamp(34.0, 48.0);

              return Row(
                children: [
                  for (var i = 0; i < _codeLength; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    _CodeCell(
                      width: cell,
                      char: _smsController.text.length > i
                          ? _smsController.text[i]
                          : '',
                      active: _smsController.text.length > i ||
                          (_smsController.text.length == i &&
                              _smsFocusNode.hasFocus),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        // Справжнє поле вводу, приховане під намальованими комірками.
        SizedBox(
          height: 0,
          width: 0,
          child: TextField(
            controller: _smsController,
            focusNode: _smsFocusNode,
            keyboardType: TextInputType.number,
            maxLength: _codeLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              setState(() {});
              if (v.length == _codeLength) {
                _handleNext(); // Авто-перевірка при заповненні
              }
            },
          ),
        ),
        const SizedBox(height: 18),
        Text(t.rg_spam_hint, style: Ds.tiny(context)),
        const SizedBox(height: 6),
        if (_resendLeft > 0)
          Text.rich(
            TextSpan(
              style: Ds.tiny(context),
              children: _splitAround(t.rg_resend_in(clock), clock, context),
            ),
          )
        else
          GestureDetector(
            onTap: _isLoading ? null : _resendCode,
            child: Text(
              t.rg_resend_now,
              style: Ds.tiny(context).copyWith(
                color: context.scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// Виділяє підставлене значення всередині перекладеного рядка.
  List<InlineSpan> _splitAround(
      String full, String value, BuildContext context) {
    final at = full.indexOf(value);
    if (at < 0) return [TextSpan(text: full)];
    return [
      TextSpan(text: full.substring(0, at)),
      TextSpan(
        text: value,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: context.scheme.onSurface,
        ),
      ),
      TextSpan(text: full.substring(at + value.length)),
    ];
  }

  // -------------------------------------------------------------- крок 4: ім'я

  Widget _nameStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.rg_name_label.toUpperCase(), style: Ds.label(context)),
        const SizedBox(height: 8),
        DsTextField(
          controller: _nameController,
          hint: t.your_name,
          enabled: !_isLoading,
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 22),
        DsCard(
          child: DsNote(
            text: t.rg_age_gate,
            icon: Icons.shield_outlined,
            iconColor: context.semantics.warning,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- крок 5: дата

  Widget _birthdayStep(AppLocalizations t) {
    final picked = _selectedDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.rg_birth_label.toUpperCase(), style: Ds.label(context)),
        const SizedBox(height: 8),
        DsFieldBox(
          focused: picked,
          onTap: _isLoading ? null : _pickDate,
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: context.scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                picked ? _birthdayController.text : t.rg_pick_date,
                style: TextStyle(
                  fontSize: 16,
                  color: picked
                      ? context.scheme.onSurface
                      : context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        DsCard(
          child: DsNote(
            text: t.rg_age_gate,
            icon: Icons.shield_outlined,
            iconColor: context.semantics.warning,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1950),
      // Застосунок для повнолітніх — молодші дати не можна навіть обрати.
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }
}

/// Одна комірка коду з `design/Code.dc.html`: заповнені підсвічені `--pri`.
class _CodeCell extends StatelessWidget {
  final double width;
  final String char;
  final bool active;

  const _CodeCell(
      {required this.width, required this.char, required this.active});

  @override
  Widget build(BuildContext context) {
    return DsFieldBox(
      width: width,
      focused: active,
      alignment: Alignment.center,
      padding: EdgeInsets.zero,
      child: Text(
        char,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: context.scheme.onSurface,
        ),
      ),
    );
  }
}
