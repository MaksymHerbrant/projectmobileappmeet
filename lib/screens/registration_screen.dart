import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_navigation_screen.dart';
import '../models/registration_model.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final PageController _pageController = PageController();
  final RegistrationModel _registrationModel = RegistrationModel();
  int _currentStep = 0;
  
  // Контролери для SMS полів
  final List<TextEditingController> _smsControllers = List.generate(
    6, 
    (index) => TextEditingController()
  );
  final List<FocusNode> _smsFocusNodes = List.generate(
    6, 
    (index) => FocusNode()
  );
  
  // Контролери для полів введення
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  // Змінні для керування видимістю паролів
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                // Стрілка назад (завжди видима)
                Positioned(
                  top: 20,
                  left: 10,
                  child: IconButton(
                    onPressed: _currentStep > 0 ? () => _previousStep() : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                  ),
                ),
                
                Column(
                  children: [
                    // Прогрес бар (без стрілки назад)
                    _buildProgressBarWithoutBackButton(),
                    
                    // Контент
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // Крок 1: Номер телефону
                          _buildPhoneStep(),
                          
                          // Крок 2: SMS код
                          _buildSmsStep(),
                          
                          // Крок 3: Email
                          _buildEmailStep(),
                          
                          // Крок 4: Пароль
                          _buildPasswordStep(),
                          
                          // Крок 5: Ім'я
                          _buildNameStep(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBarWithoutBackButton() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 40),
      child: Row(
        children: [
          const Spacer(),
          
          // Прогрес текст
          Text(
            '${AppLocalizations.of(context)!.step} ${_currentStep + 1} ${AppLocalizations.of(context)!.of_text} ${RegistrationModel.totalSteps}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Заголовок
          Text(
            AppLocalizations.of(context)!.phone_number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Підзаголовок
          Text(
            AppLocalizations.of(context)!.enter_phone_for_sms,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Поле для номера телефону
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Прапорець країни
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/ukraine.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '+380',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Розділювач
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                
                // Поле для номера
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.phone_number,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '', // Приховуємо лічильник символів
                    ),
                    onChanged: (value) {
                      // Обмежуємо введення тільки цифрами
                      final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digitsOnly.length <= 9) {
                        _phoneController.text = digitsOnly;
                        _phoneController.selection = TextSelection.fromPosition(
                          TextPosition(offset: digitsOnly.length),
                        );
                        _registrationModel.phoneNumber = digitsOnly;
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Кнопка продовжити
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registrationModel.isStep1Valid() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _registrationModel.isStep1Valid() 
                  ? const Color(0xFF5C72FF) 
                  : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.continue_text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmsStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // Зменшено з 40 до 20
          
          // Заголовок
          Text(
            AppLocalizations.of(context)!.sms_code,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Підзаголовок
          Text(
            '${AppLocalizations.of(context)!.enter_code_sent_to} ${_phoneController.text}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 20), // Зменшено з 40 до 20
          
          // SMS поля
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 45,
                child: TextField(
                  controller: _smsControllers[index],
                  focusNode: _smsFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF5C72FF)),
                    ),
                  ),
                  onChanged: (value) {
                    // Обмежуємо введення тільки цифрами
                    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digitsOnly.length <= 1) {
                      _smsControllers[index].text = digitsOnly;
                      _smsControllers[index].selection = TextSelection.fromPosition(
                        TextPosition(offset: digitsOnly.length),
                      );
                      
                      if (digitsOnly.isNotEmpty && index < 5) {
                        _smsFocusNodes[index + 1].requestFocus();
                      }
                      _registrationModel.smsCode = _getSmsCode();
                      setState(() {});
                    }
                  },
                ),
              );
            }),
          ),
          
          const SizedBox(height: 20),
          
          // Кнопка повторного надсилання
          Center(
            child: TextButton(
              onPressed: () {
                // Логіка повторного надсилання SMS
              },
              child: Text(
                AppLocalizations.of(context)!.send_code_again,
                style: const TextStyle(
                  color: Color(0xFF5C72FF),
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Кнопка продовжити
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registrationModel.isStep2Valid() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _registrationModel.isStep2Valid() 
                  ? const Color(0xFF5C72FF) 
                  : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.continue_text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSmsCode() {
    return _smsControllers.map((controller) => controller.text).join();
  }

  Widget _buildEmailStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // Зменшено з 40 до 20
          
          // Заголовок
          Text(
            AppLocalizations.of(context)!.email,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Підзаголовок
          Text(
            AppLocalizations.of(context)!.enter_your_email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 20), // Зменшено з 40 до 20
          
          // Поле для email
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.email,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                _registrationModel.email = value;
                setState(() {});
              },
            ),
          ),
          
          const Spacer(),
          
          // Кнопка продовжити
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registrationModel.isStep3Valid() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _registrationModel.isStep3Valid() 
                  ? const Color(0xFF5C72FF) 
                  : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.continue_text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // Зменшено з 40 до 20
          
          // Заголовок
          Text(
            AppLocalizations.of(context)!.password,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Підзаголовок
          Text(
            AppLocalizations.of(context)!.create_strong_password,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 20), // Зменшено з 40 до 20
          
          // Поле для пароля
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.password,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              onChanged: (value) {
                _registrationModel.password = value;
                setState(() {});
              },
            ),
          ),
          
          const SizedBox(height: 15), // Зменшено з 20 до 15
          
          // Поле для підтвердження пароля
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.confirm_password,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              onChanged: (value) {
                _registrationModel.confirmPassword = value;
                setState(() {});
              },
            ),
          ),
          
          const Spacer(),
          
          // Кнопка продовжити
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registrationModel.isStep4Valid() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _registrationModel.isStep4Valid() 
                  ? const Color(0xFF5C72FF) 
                  : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.continue_text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // Зменшено з 40 до 20
          
          // Заголовок
          Text(
            AppLocalizations.of(context)!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Підзаголовок
          Text(
            AppLocalizations.of(context)!.what_is_your_name,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 20), // Зменшено з 40 до 20
          
          // Поле для імені
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.name,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                _registrationModel.name = value;
                setState(() {});
              },
            ),
          ),
          
          const SizedBox(height: 20), // Зменшено з 40 до 20
          
          // Кнопка завершити
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registrationModel.isStep5Valid() 
                ? () => _completeRegistration() 
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _registrationModel.isStep5Valid() 
                  ? const Color(0xFF5C72FF) 
                  : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.register,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < RegistrationModel.totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      // Очищаємо дані поточного кроку
      _registrationModel.clearCurrentStepData(_currentStep + 1);
      
      // Очищаємо контролери відповідно до кроку
      switch (_currentStep) {
        case 1: // SMS крок
          for (var controller in _smsControllers) {
            controller.clear();
          }
          break;
        case 2: // Email крок
          _emailController.clear();
          break;
        case 3: // Пароль крок
          _passwordController.clear();
          _confirmPasswordController.clear();
          _isPasswordVisible = false;
          _isConfirmPasswordVisible = false;
          break;
        case 4: // Ім'я крок
          _nameController.clear();
          break;
      }
      
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeRegistration() {
    // TODO: Відправити дані на сервер
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppLocalizations.of(context)!.registration} ${AppLocalizations.of(context)!.success}!'),
        backgroundColor: const Color(0xFF5C72FF),
      ),
    );
    
    // Перехід до головного екрану
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
    );
  }
} 