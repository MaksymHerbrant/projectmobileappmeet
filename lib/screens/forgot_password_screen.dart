import '../theme/app_theme.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _smsFocusNode = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _smsFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      if (_currentStep == 0) {
        // КРОК 1: ТЕЛЕФОН
        final phone = _phoneController.text.trim();
        if (phone.length < 9)
          throw Exception(AppLocalizations.of(context)!.enter_valid_phone);

        // Перевіряємо, чи Є такий користувач
        final bool exists = await _authService.checkUserExists(phone);
        if (!exists) {
          throw Exception(AppLocalizations.of(context)!.fp_not_found);
        }

        // Відправляємо SMS
        await _authService.signInWithPhone(phone);
        _goToNextPage();

        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _smsFocusNode.requestFocus();
        });
      } else if (_currentStep == 1) {
        // КРОК 2: SMS
        if (_smsController.text.length < 6)
          throw Exception(AppLocalizations.of(context)!.rg_code_incomplete);
        // Перевірка коду авторизує користувача
        await _authService.verifyOtp(
            _phoneController.text, _smsController.text);
        _goToNextPage();
      } else if (_currentStep == 2) {
        // КРОК 3: НОВИЙ ПАРОЛЬ
        if (_passwordController.text.length < 6)
          throw Exception(AppLocalizations.of(context)!.rg_password_short);
        if (_passwordController.text != _confirmPasswordController.text)
          throw Exception(AppLocalizations.of(context)!.passwords_do_not_match);

        // Оновлюємо пароль у базі
        await _authService.updatePassword(_passwordController.text);

        // Опціонально: робимо logout і відправляємо на вхід
        await _authService.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.password_changed),
                backgroundColor:
                    Theme.of(context).extension<AppSemantics>()!.success),
          );
          // Повертаємось на екран входу
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception:', '').trim()),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: _isLoading
              ? null
              : (_currentStep > 0
                  ? _previousStep
                  : () => Navigator.pop(context)),
        ),
        title: Text(
            AppLocalizations.of(context)!.recovery_step_of(_currentStep + 1, 3),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14)),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep(
              title: AppLocalizations.of(context)!.fp_title,
              subtitle: AppLocalizations.of(context)!.fp_enter_phone,
              content: _buildPhoneInput()),
          _buildStep(
              title: AppLocalizations.of(context)!.rg_sms_title,
              subtitle: AppLocalizations.of(context)!.rg_enter_6,
              content: _buildSmsInput()),
          _buildStep(
              title: AppLocalizations.of(context)!.new_password,
              subtitle: AppLocalizations.of(context)!.fp_new_strong,
              content: _buildPasswordInput()),
        ],
      ),
    );
  }

  Widget _buildStep(
      {required String title,
      required String subtitle,
      required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(title,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 40),
          content,
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(AppLocalizations.of(context)!.continue_text,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      enabled: !_isLoading,
      autofocus: true,
      decoration: InputDecoration(
        prefixText: '+380 ',
        prefixStyle: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: 'XX XXX XXXX',
      ),
    );
  }

  Widget _buildSmsInput() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _smsFocusNode.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              String char = "";
              if (_smsController.text.length > index)
                char = _smsController.text[index];
              bool isFocused = _smsController.text.length == index;
              return Container(
                width: 45,
                height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                      color: isFocused
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(char,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              );
            }),
          ),
        ),
        SizedBox(
          height: 0,
          width: 0,
          child: TextField(
            controller: _smsController,
            focusNode: _smsFocusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (v) {
              setState(() {});
              if (v.length == 6) _handleNext();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInput() {
    return Column(
      children: [
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.new_password,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.confirm_new_password,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }
}
