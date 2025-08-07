import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  
  const ProfileDetailScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  int _currentPhotoIndex = 0;
  final PageController _photoController = PageController();

  // Функція для локалізації хобі
  List<String> _getLocalizedHobbies(List<dynamic> hobbies, BuildContext context) {
    Map<String, String> hobbyTranslations = {
      'Фентезі книги': AppLocalizations.of(context)!.fantasy_books,
      'Похід з наметом': AppLocalizations.of(context)!.camping,
      'Ранкова кава з видом на гори': AppLocalizations.of(context)!.morning_coffee,
      'Гра на гітарі': AppLocalizations.of(context)!.guitar,
      'Фотографія': AppLocalizations.of(context)!.photography,
      'Кулінарія': AppLocalizations.of(context)!.cooking,
      'Подорожі': AppLocalizations.of(context)!.travel,
      'Спорт': AppLocalizations.of(context)!.sport,
      'Читання': AppLocalizations.of(context)!.reading,
      'Йога': AppLocalizations.of(context)!.yoga,
      'Медитація': AppLocalizations.of(context)!.meditation,
      'Велоспорт': AppLocalizations.of(context)!.cycling,
      'Мистецтво': AppLocalizations.of(context)!.art,
      'Фітнес': AppLocalizations.of(context)!.fitness,
      'Гори': AppLocalizations.of(context)!.mountains,
      'Бокс': AppLocalizations.of(context)!.boxing,
      'Плавання': AppLocalizations.of(context)!.swimming,
      'Біг': AppLocalizations.of(context)!.running,
      'Здорове харчування': AppLocalizations.of(context)!.healthy_nutrition,
      'Мотивація': AppLocalizations.of(context)!.motivation,
    };
    
    return hobbies.map((hobby) => hobbyTranslations[hobby.toString()] ?? hobby.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFF3E5F5), Colors.white],
          ),
        ),
        child: SafeArea(
        child: Column(
          children: [
            // Верхня панель
            _buildTopBar(),
            
            // Основний контент
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Фото користувача
                    _buildPhotoSection(),
                    
                    // Інформація про користувача
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ім'я та вік
                          Text(
                            '${widget.profile['name'] ?? AppLocalizations.of(context)!.unknown}, ${widget.profile['age'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Локація та відстань
                          _buildInfoRow(Icons.location_on, 'м.${widget.profile['location'] ?? AppLocalizations.of(context)!.unknown}'),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.access_time, widget.profile['distance'] ?? AppLocalizations.of(context)!.distance),
                          
                          const SizedBox(height: 20),
                          
                          // Опис
                          if ((widget.profile['aboutMe'] ?? '').isNotEmpty) ...[
                            Text(
                              AppLocalizations.of(context)!.about_me,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.profile['aboutMe'] ?? 'Опис відсутній',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Хобі
                          if ((widget.profile['hobbies'] as List<dynamic>?)?.isNotEmpty == true) ...[
                            Text(
                              AppLocalizations.of(context)!.hobbies,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _getLocalizedHobbies(widget.profile['hobbies'] as List<dynamic>? ?? [], context).map<Widget>((hobby) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E5F5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color.fromARGB(255, 147, 163, 216)),
                                  ),
                                  child: Text(
                                    hobby,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color.fromARGB(255, 31, 92, 162),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Нижня панель дій
            _buildBottomActions(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Кнопка назад
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          
          const Spacer(),
          
          // Назва екрану
          Text(
            AppLocalizations.of(context)!.user_profile,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const Spacer(),
          
          // Порожній простір для балансу
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      height: 300,
      child: Stack(
        children: [
          // Карусель фото
          PageView.builder(
            controller: _photoController,
            itemCount: (widget.profile['photos'] as List<dynamic>?)?.length ?? 0,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemBuilder: (context, photoIndex) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(widget.profile['photos']?[photoIndex] ?? 'assets/images/portrait-man-laughing.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          
          // Індикатор фото
          if ((widget.profile['photos'] as List<dynamic>?)?.isNotEmpty == true && (widget.profile['photos'] as List<dynamic>?)!.length > 1)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate((widget.profile['photos'] as List<dynamic>?)?.length ?? 0, (index) {
                  return Container(
                    width: index == _currentPhotoIndex ? 12 : 8,
                    height: index == _currentPhotoIndex ? 12 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index == _currentPhotoIndex ? Colors.white : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade600,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Кнопка "Не подобається"
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.dislike,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Кнопка "Подобається"
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Логіка лайку
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 109, 245),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.like,
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
} 