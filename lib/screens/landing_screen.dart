import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'registration_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        debugPrint('Landing screen - Current locale: ${localeProvider.locale.languageCode}_${localeProvider.locale.countryCode}');
        debugPrint('Landing screen - already_have_account: ${AppLocalizations.of(context)!.already_have_account}');
        debugPrint('Landing screen - enter: ${AppLocalizations.of(context)!.enter}');
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final imageSize = screenWidth; // Базова ширина для позиціювання
        
        // Визначаємо чи це маленький екран (iPhone SE тощо)
        final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFF3E5F5), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            // Текст Bondee
            Positioned(
              top: 40,
              left: 24,
              child: Text(
                AppLocalizations.of(context)!.app_name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Arial',
                ),
              ),
            ),
            
            // 📸 Колаж із 7 круглих фото з точними координатами
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Stack(
                  children: [
                    // Центральне фото (найбільше)
                    Positioned(
                      top: screenWidth * (isSmallScreen ? 0.3 : 0.4), // Вище на маленьких екранах
                      left: screenWidth * 0.25,
                      child: Container(
                        width: screenWidth * (isSmallScreen ? 0.22 : 0.25) * 2, // Збільшено до 44% для маленьких екранів
                        height: screenWidth * (isSmallScreen ? 0.22 : 0.25) * 2, // Збільшено до 44% для маленьких екранів
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/portrait-man-laughing.jpg'),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Ліве верхнє фото
                    Positioned(
                      top: screenWidth * 0.02,
                      left: screenWidth * 0.05,
                      child: Container(
                        width: screenWidth * (isSmallScreen ? 0.18 : 0.2) * 2, // Збільшено до 36% для маленьких екранів
                        height: screenWidth * (isSmallScreen ? 0.18 : 0.2) * 2, // Збільшено до 36% для маленьких екранів
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/close-up-portrait-curly-handsome-european-male.jpg'),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Праве верхнє фото
                    Positioned(
                      top: screenWidth * -0.01,
                      right: screenWidth * 0.01,
                      child: Container(
                        width: screenWidth * (isSmallScreen ? 0.18 : 0.22) * 2, // Залишено 36% для маленьких екранів
                        height: screenWidth * (isSmallScreen ? 0.18 : 0.22) * 2, // Залишено 36% для маленьких екранів
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/pleased-smiling-man-with-beard-looking-camera.jpg'),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Ліве нижнє фото
                    Positioned(
                      bottom: screenWidth * 0.3,
                      left: screenWidth * -0.1,
                      child: Container(
                        width: screenWidth * (isSmallScreen ? 0.15 : 0.16) * 2, // Збільшено до 30% для маленьких екранів
                        height: screenWidth * (isSmallScreen ? 0.13 : 0.16) * 2, // Збільшено до 30% для маленьких екранів
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/selfie-portrait-videocall.jpg'),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Праве нижнє фото
                    Positioned(
                      bottom: screenWidth * 0.2,
                      right: screenWidth * -0.09,
                      child: Container(
                        width: screenWidth * (isSmallScreen ? 0.15 : 0.16) * 2, // Збільшено до 30% для маленьких екранів
                        height: screenWidth * (isSmallScreen ? 0.15 : 0.16) * 2, // Збільшено до 30% для маленьких екранів
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/portrait-man-laughing.jpg'),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  children: [
                    SizedBox(height: isSmallScreen ? 300 : 370), // Менший відступ для маленьких екранів
                
                    // Нижній блок - займає решту простору
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Заголовок
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: isSmallScreen ? 22 : 26, // Менший шрифт для маленьких екранів
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                height: isSmallScreen ? 1.2 : 1.25, // Менша висота для маленьких екранів
                              ),
                              children: [
                                TextSpan(text: AppLocalizations.of(context)!.find_your_wave),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Підзаголовок
                          Text(
                            AppLocalizations.of(context)!.become_part_of_community,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15, // Менший шрифт для маленьких екранів
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: isSmallScreen ? 20 : 30), // Менший відступ для маленьких екранів
                          
                          // Кнопка "Почнімо"
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const RegistrationScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14), // Зменшено з 18 до 14
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.lets_start,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 16 : 20), // Менший відступ для маленьких екранів
                          
                          // Текст "Продовжити через"
                          Text(
                            AppLocalizations.of(context)!.continue_with,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 12 : 16), // Менший відступ для маленьких екранів
                          
                          // Кнопки соціальних мереж
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google кнопка
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Image.asset(
                                    'assets/icons/google.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 10),
                              
                              // Apple кнопка
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.apple,
                                  size: 45, // Збільшено на 30%
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isSmallScreen ? 20 : 24), // Менший відступ для маленьких екранів
                          
                          // Текст "Вже маєте акаунт?"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${AppLocalizations.of(context)!.already_have_account} ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.enter,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF4A90E2),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isSmallScreen ? 12 : 16), // Менший відступ для маленьких екранів // Повернуто з 8 до 16
                        ],
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