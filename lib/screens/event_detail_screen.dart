import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  
  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int _currentPhotoIndex = 0;
  final PageController _photoController = PageController();

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');
    final dateString = dateFormat.format(widget.event.dateTime);
    
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
                    // Фото заходу
                    _buildPhotoSection(),
                    
                    // Інформація про захід
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Назва заходу
                          Text(
                            widget.event.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Місце та дата
                          _buildInfoRow(Icons.location_on, widget.event.location),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.access_time, dateString),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.people, '${widget.event.participantsCount} ${AppLocalizations.of(context)!.participants}'),
                          
                          const SizedBox(height: 20),
                          
                          // Опис
                          if (widget.event.description.isNotEmpty) ...[
                            Text(
                              AppLocalizations.of(context)!.event_description,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.event.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Теги
                          if (widget.event.tags.isNotEmpty) ...[
                            Text(
                              AppLocalizations.of(context)!.tags,
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
                              children: widget.event.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E5F5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color.fromARGB(255, 147, 163, 216)),
                                  ),
                                  child: Text(
                                    tag,
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
            AppLocalizations.of(context)!.event_details,
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
            itemCount: widget.event.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemBuilder: (context, photoIndex) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(widget.event.photos[photoIndex]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          
          // Індикатор фото
          if (widget.event.photos.length > 1)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.event.photos.length, (index) {
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
          // Кнопка "Не цікавить"
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
                  AppLocalizations.of(context)!.not_interested,
                  style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Кнопка "Приєднатися"
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Логіка приєднання до заходу
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
                  AppLocalizations.of(context)!.join,
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