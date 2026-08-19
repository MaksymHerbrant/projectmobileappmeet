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
  static const int _stepCount = 5;

  /// Скільки секунд чекати до повторного SMS.
  static const int _resendSeconds = 60;

  final _authService = AuthService();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        // КРОК 1: ТЕЛЕФОН
        final phone = _phoneController.text.trim();
        if (phone.length < 9)
          throw Exception(AppLocalizations.of(context)!.enter_valid_phone);

        // 🟢 ЖОРСТКА ПЕРЕВІРКА: чи є номер у таблиці profiles
        final bool exists = await _authService.checkUserExists(phone);

        if (exists) {
          // Якщо акаунт є — СТОП. Не шлемо SMS, не пускаємо далі.
          setState(() => _isLoading = false);
          _showUserExistsDialog();
          return;
        }

        // Якщо номера немає — шлемо SMS і тільки тоді йдемо далі
        await _authService.signInWithPhone(phone);
        _startResendCountdown();
        _goToNextPage();

        // Активуємо фокус на SMS після переходу
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _smsFocusNode.requestFocus();
        });
      } else if (_currentStep == 1) {
        // КРОК 2: SMS
        if (_smsController.text.length < 6)
          throw Exception(AppLocalizations.of(context)!.rg_code_incomplete);
        await _authService.verifyOtp(
            _phoneController.text, _smsController.text);
        _goToNextPage();
      } else if (_currentStep == 2) {
        // КРОК 3: ПАРОЛЬ
        if (_passwordController.text.length < 6)
          throw Exception(AppLocalizations.of(context)!.rg_password_short);
        if (_passwordController.text != _confirmPasswordController.text)
          throw Exception(AppLocalizations.of(context)!.passwords_do_not_match);
        _goToNextPage();
      } else if (_currentStep == 3) {
        // КРОК 4: ІМ'Я
        if (_nameController.text.trim().isEmpty)
          throw const AppFailure(FailureKind.save);
        _goToNextPage();
      } else if (_currentStep == 4) {
        // КРОК 5: ДАТА
        if (_selectedDate == null)
          throw Exception(AppLocalizations.of(context)!.rg_need_birth);
        await _completeRegistration();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')),
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
      await _authService.signInWithPhone(_phoneController.text.trim());
      _startResendCountdown();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showUserExistsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.account_exists_title),
        content: Text(AppLocalizations.of(context)!.account_exists_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.change_number),
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
            title: t.rg_your_phone,
            subtitle: t.rg_check_free,
            content: _phoneStep(t),
          ),
          _step(
            title: t.rg_sms_title,
            subtitle: null,
            subtitleWidget: _sentToLine(t),
            content: _smsStep(t),
          ),
          _step(
            title: t.rg_protect,
            subtitle: t.rg_strong_password,
            content: _passwordStep(t),
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
        1 => t.rg_confirm,
        4 => t.continue_text,
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

  // ------------------------------------------------------------- крок 1: номер

  Widget _phoneStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DsFieldBox(
              width: 96,
              alignment: Alignment.center,
              child: Text(
                '+380',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DsTextField(
                controller: _phoneController,
                hint: '67 123 45 67',
                keyboardType: TextInputType.phone,
                enabled: !_isLoading,
                autofocus: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DsNote(text: t.rg_phone_note),
      ],
    );
  }

  // --------------------------------------------------------------- крок 2: код

  Widget _sentToLine(AppLocalizations t) {
    // Номер виділено, як у макеті. Збирати рядок конкатенацією не можна —
    // у різних мовах номер стоїть у різних місцях, тож ріжемо готовий переклад.
    final phone = '+380 ${_phoneController.text.trim()}';
    final full = t.rg_sms_sent_to(phone);
    final at = full.indexOf(phone);

    if (at < 0) return Text(full, style: Ds.sub(context));

    return Text.rich(
      TextSpan(
        style: Ds.sub(context),
        children: [
          TextSpan(text: full.substring(0, at)),
          TextSpan(
            text: phone,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.scheme.onSurface,
            ),
          ),
          TextSpan(text: full.substring(at + phone.length)),
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
              final cell =
                  ((constraints.maxWidth - gap * 5) / 6).clamp(34.0, 48.0);

              return Row(
                children: [
                  for (var i = 0; i < 6; i++) ...[
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
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              setState(() {});
              if (v.length == 6) _handleNext(); // Авто-перевірка при заповненні
            },
          ),
        ),
        const SizedBox(height: 18),
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

  // ------------------------------------------------------------ крок 3: пароль

  Widget _passwordStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.password.toUpperCase(), style: Ds.label(context)),
        const SizedBox(height: 8),
        DsTextField(
          controller: _passwordController,
          obscure: !_isPasswordVisible,
          enabled: !_isLoading,
          suffix: GestureDetector(
            onTap: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
            child: Icon(
              _isPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(t.confirm_password.toUpperCase(), style: Ds.label(context)),
        const SizedBox(height: 8),
        DsTextField(
          controller: _confirmPasswordController,
          obscure: !_isPasswordVisible,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 22),
        DsCard(
          child: DsNote(
            text: t.rg_password_note,
            icon: Icons.lock_outline_rounded,
          ),
        ),
      ],
    );
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
