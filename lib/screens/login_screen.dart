import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';// Для обробки помилок
import '../providers/locale_provider.dart';
import '../service/auth_service.dart';
import 'main_navigation_screen.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  
  // Контролери
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Проста валідація
    if (_phoneController.text.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введіть коректний номер')));
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введіть пароль')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 👇 Викликаємо вхід за паролем
      await _authService.signInWithPassword(
        _phoneController.text, 
        _passwordController.text
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
          const SnackBar(
            content: Text('Невірний номер або пароль'), 
            backgroundColor: Colors.red
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

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Кнопка назад
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 28),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Заголовок
                  Text(
                    t.login_title, // "Вхід"
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // --- ПОЛЕ ТЕЛЕФОНУ ---
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Image.asset('assets/icons/ukraine.png', width: 25),
                            const SizedBox(width: 8),
                            const Text('+380', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade300),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            decoration: InputDecoration(
                              hintText: t.phone_number,
                              border: InputBorder.none, 
                              contentPadding: const EdgeInsets.all(16),
                              counterText: '', // Ховає лічильник символів
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // --- ПОЛЕ ПАРОЛЯ ---
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: t.password, // "Пароль"
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // --- КНОПКА ВХОДУ ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C72FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(t.enter, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  
                  // Кнопка "Забули пароль?" (Можна додати пізніше)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // 👇 Переходимо на екран відновлення
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text('Забули пароль?', style: TextStyle(color: Colors.grey)),
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