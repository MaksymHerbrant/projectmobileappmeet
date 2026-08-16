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
        if (phone.length < 9) throw Exception('Введіть коректний номер');

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
        if (_smsController.text.length < 6) throw Exception('Введіть код повністю');
        await _authService.verifyOtp(_phoneController.text, _smsController.text);
        _goToNextPage();

      } else if (_currentStep == 2) {
        // КРОК 3: ПАРОЛЬ
        if (_passwordController.text.length < 6) throw Exception('Пароль занадто короткий');
        if (_passwordController.text != _confirmPasswordController.text) throw Exception('Паролі не збігаються');
        _goToNextPage();

      } else if (_currentStep == 3) {
        // КРОК 4: ІМ'Я
        if (_nameController.text.trim().isEmpty) throw Exception('Введіть ваше ім\'я');
        _goToNextPage();

      } else if (_currentStep == 4) {
        // КРОК 5: ДАТА
        if (_selectedDate == null) throw Exception('Вкажіть дату народження');
        await _completeRegistration();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')), 
            backgroundColor: Colors.red
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
        title: const Text('Акаунт уже існує'),
        content: const Text('Ви вже зареєстровані в системі. Будь ласка, увійдіть у свій профіль або скористайтеся іншим номером.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Змінити номер'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Закрити діалог
              Navigator.pop(context); // Повернутися на екран входу (Login)
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C72FF)),
            child: const Text('Увійти', style: TextStyle(color: Colors.white)),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isLoading ? null : (_currentStep > 0 ? _previousStep : () => Navigator.pop(context)),
        ),
        title: Text('Крок ${_currentStep + 1} з 5', style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep(title: 'Ваш номер телефону', subtitle: 'Ми перевіримо, чи вільний цей номер', content: _buildPhoneInput()),
          _buildStep(title: 'Підтвердження SMS', subtitle: 'Введіть 6 цифр, що надійшли на номер', content: _buildSmsInput()),
          _buildStep(title: 'Захистіть акаунт', subtitle: 'Придумайте надійний пароль', content: _buildPasswordInput()),
          _buildStep(title: 'Знайомство', subtitle: 'Як до вас звертатися?', content: _buildNameInput()),
          _buildStep(title: 'Вік', subtitle: 'Тільки для повнолітніх (18+)', content: _buildBirthdayInput()),
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
          Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 40),
          content,
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C72FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Продовжити', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
        prefixStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
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
                  color: Colors.grey.shade50,
                  border: Border.all(color: isFocused ? const Color(0xFF5C72FF) : Colors.grey.shade300, width: 2),
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
            labelText: 'Пароль',
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
          decoration: InputDecoration(labelText: 'Підтвердіть пароль', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(hintText: 'Ваше ім\'я', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
        hintText: 'Оберіть дату народження',
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}