import '../theme/app_theme.dart';
import '../service/error_reporter.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main_navigation_screen.dart';
import '../service/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _authService = AuthService();
  final PageController _pageController = PageController();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Контролери
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  
  // SMS контролер та фокус
  final TextEditingController _smsController = TextEditingController();
  final FocusNode _smsFocusNode = FocusNode();

  DateTime? _selectedDate;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _birthdayController.dispose();
    _smsController.dispose();
    _smsFocusNode.dispose();
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
        if (phone.length < 9) throw Exception(AppLocalizations.of(context)!.enter_valid_phone);

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
        _goToNextPage();
        
        // Активуємо фокус на SMS після переходу
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _smsFocusNode.requestFocus();
        });

      } else if (_currentStep == 1) {
        // КРОК 2: SMS
        if (_smsController.text.length < 6) throw Exception(AppLocalizations.of(context)!.rg_code_incomplete);
        await _authService.verifyOtp(_phoneController.text, _smsController.text);
        _goToNextPage();

      } else if (_currentStep == 2) {
        // КРОК 3: ПАРОЛЬ
        if (_passwordController.text.length < 6) throw Exception(AppLocalizations.of(context)!.rg_password_short);
        if (_passwordController.text != _confirmPasswordController.text) throw Exception(AppLocalizations.of(context)!.passwords_do_not_match);
        _goToNextPage();

      } else if (_currentStep == 3) {
        // КРОК 4: ІМ'Я
        if (_nameController.text.trim().isEmpty) throw const AppFailure(FailureKind.save);
        _goToNextPage();

      } else if (_currentStep == 4) {
        // КРОК 5: ДАТА
        if (_selectedDate == null) throw Exception(AppLocalizations.of(context)!.rg_need_birth);
        await _completeRegistration();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')), 
            backgroundColor: Theme.of(context).colorScheme.error
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: Text(AppLocalizations.of(context)!.login, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep--);
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // --- UI БУДІВНИЦТВО ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: _isLoading ? null : (_currentStep > 0 ? _previousStep : () => Navigator.pop(context)),
        ),
        title: Text(AppLocalizations.of(context)!.step_of(_currentStep + 1, 5), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep(title: AppLocalizations.of(context)!.rg_your_phone, subtitle: AppLocalizations.of(context)!.rg_check_free, content: _buildPhoneInput()),
          _buildStep(title: AppLocalizations.of(context)!.rg_sms_title, subtitle: AppLocalizations.of(context)!.rg_enter_6, content: _buildSmsInput()),
          _buildStep(title: AppLocalizations.of(context)!.rg_protect, subtitle: AppLocalizations.of(context)!.rg_strong_password, content: _buildPasswordInput()),
          _buildStep(title: AppLocalizations.of(context)!.rg_meet, subtitle: AppLocalizations.of(context)!.rg_how_to_call, content: _buildNameInput()),
          _buildStep(title: AppLocalizations.of(context)!.rg_age, subtitle: AppLocalizations.of(context)!.rg_adults_only, content: _buildBirthdayInput()),
        ],
      ),
    );
  }

  Widget _buildStep({required String title, required String subtitle, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(AppLocalizations.of(context)!.continue_text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
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
        prefixStyle: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
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
              if (_smsController.text.length > index) char = _smsController.text[index];
              bool isFocused = _smsController.text.length == index;
              return Container(
                width: 45, height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(color: isFocused ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(char, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              );
            }),
          ),
        ),
        SizedBox(
          height: 0, width: 0,
          child: TextField(
            controller: _smsController,
            focusNode: _smsFocusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (v) {
              setState(() {});
              if (v.length == 6) _handleNext(); // Авто-перевірка при заповненні
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
            labelText: AppLocalizations.of(context)!.password,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.confirm_password, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(hintText: AppLocalizations.of(context)!.your_name, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildBirthdayInput() {
    return TextField(
      controller: _birthdayController,
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2005),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _birthdayController.text = DateFormat('dd.MM.yyyy').format(picked);
          });
        }
      },
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.pick_birth_date,
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}