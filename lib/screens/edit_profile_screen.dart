import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../service/matches_service.dart'; // 👇 ВАЖЛИВО: Імпорт для VectorUtils

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfileScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Клієнт Supabase
  final _supabase = Supabase.instance.client;

  // Контролери
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  TextEditingController? _hobbySearchController;
  
  // 🟢 Координати для "Розумного пошуку"
  double? _latitude;
  double? _longitude;
  
  // Дата народження
  DateTime? _birthDate;

  // Фото
  List<String> _existingPhotoUrls = []; 
  List<File> _newPhotoFiles = [];       
  bool _isUploading = false;            

  // Хобі
  List<String> _selectedHobbies = [];
  final List<String> _availableHobbies = [
    'Геймінг', 'Настільні ігри', 'Музика Lo-Fi', 'Похід з наметом',
    'Фентезі книги', 'Фотографія', 'Подорожі', 'Кулінарія',
    'Спорт', 'Читання', 'Музика', 'Танці', 'Малювання',
    'Програмування', 'Йога', 'Біг', 'Велоспорт', 'Плавання',
  ];
  List<String> _filteredHobbies = [];
  String _hobbySearchQuery = '';

  @override
  void initState() {
    super.initState();
    // Ініціалізація полів
    _nameController = TextEditingController(text: widget.profileData['name'] ?? '');
    _locationController = TextEditingController(text: widget.profileData['location'] ?? '');
    _bioController = TextEditingController(text: widget.profileData['aboutMe'] ?? '');
    
    // Ініціалізація дати
    if (widget.profileData['birthDate'] is DateTime) {
      _birthDate = widget.profileData['birthDate'];
    } else if (widget.profileData['birthDate'] is String) {
      try {
        _birthDate = DateTime.parse(widget.profileData['birthDate']);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    // Фото
    if (widget.profileData['photos'] != null) {
      _existingPhotoUrls = List<String>.from(widget.profileData['photos']);
    }

    _hobbySearchController = TextEditingController();
    
    // Хобі
    if (widget.profileData['hobbies'] != null) {
      _selectedHobbies = List<String>.from(widget.profileData['hobbies']);
    }
    _filteredHobbies = List.from(_availableHobbies);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _hobbySearchController?.dispose();
    super.dispose();
  }

  // --- ЛОГІКА РОБОТИ З ФОТО ---

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Оптимізація розміру
      maxWidth: 1080,
      maxHeight: 1920,
    );

    if (image != null) {
      setState(() {
        _newPhotoFiles.add(File(image.path));
      });
    }
  }

  void _removeExistingPhoto(String url) {
    setState(() {
      _existingPhotoUrls.remove(url);
    });
  }

  void _removeNewPhoto(File file) {
    setState(() {
      _newPhotoFiles.remove(file);
    });
  }

  Future<List<String>> _uploadNewPhotos() async {
    List<String> uploadedUrls = [];
    final userId = _supabase.auth.currentUser!.id;

    for (var i = 0; i < _newPhotoFiles.length; i++) {
      try {
        final file = _newPhotoFiles[i];
        final fileExt = file.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$fileExt';
        final filePath = '$userId/$fileName';

        await _supabase.storage.from('avatars').upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

        final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
        uploadedUrls.add(imageUrl);
      } catch (e) {
        debugPrint("Помилка завантаження фото: $e");
      }
    }
    return uploadedUrls;
  }

  // --- ЛОГІКА ВИБОРУ ДАТИ ---

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2005, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  // --- 🟢 ЛОГІКА ЗБЕРЕЖЕННЯ (ОНОВЛЕНА) ---

  Future<void> _saveProfile() async {
    // 1. Валідація
    if (_nameController.text.trim().isEmpty) { _showErrorDialog('Введіть ваше ім\'я'); return; }
    if (_locationController.text.trim().isEmpty) { _showErrorDialog('Введіть місце знаходження'); return; }
    if (_birthDate == null) { _showErrorDialog('Будь ласка, вкажіть дату народження'); return; }

    setState(() => _isUploading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;

      // 2. Визначаємо координати
      double lat = _latitude ?? 0;
      double long = _longitude ?? 0;

      // Якщо це ручне введення міста (без GPS), пробуємо знайти координати
      if (lat == 0 && long == 0 && _locationController.text.isNotEmpty) {
        try {
          List<Location> locations = await locationFromAddress(_locationController.text);
          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            long = locations.first.longitude;
          }
        } catch (e) {
          debugPrint("Не вдалося геокодувати адресу: $e");
        }
      }

      // 3. Генеруємо вектор інтересів
      final vector = VectorUtils.tagsToVector(_selectedHobbies);

      // 4. Завантажуємо нові фото
      final newUploadedUrls = await _uploadNewPhotos();
      final List<String> finalPhotoList = [..._existingPhotoUrls, ...newUploadedUrls];

      // 5. Оновлюємо базу даних (ОДНИМ ЗАПИТОМ)
      final Map<String, dynamic> updates = {
        'full_name': _nameController.text.trim(),
        'birth_date': _birthDate!.toIso8601String().split('T')[0],
        'bio': _bioController.text.trim(),
        'hobbies': _selectedHobbies,
        'photos': finalPhotoList,
        'embedding': vector.toString(),
        
        // 👇 ВАЖЛИВЕ ВИПРАВЛЕННЯ 👇
        // У колонку 'location' пишемо ТІЛЬКИ ТЕКСТ (назву міста)
        'location': _locationController.text.trim(), 
      };

      // Якщо координати існують, додаємо їх у СПЕЦІАЛЬНУ колонку location_point
      if (lat != 0 && long != 0) {
        updates['location_point'] = '($lat,$long)';
      }

      await _supabase.from('profiles').update(updates).eq('id', userId);

      // 6. Повертаємо дані в UI
      final uiData = {
        'name': updates['full_name'],
        'location': updates['location'], // Повертаємо саме текст!
        'birthDate': _birthDate, 
        'aboutMe': updates['bio'],
        'hobbies': updates['hobbies'],
        'photos': finalPhotoList,
      };

      if (mounted) {
        Navigator.of(context).pop(uiData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профіль успішно оновлено!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Full save error: $e");
      if (mounted) _showErrorDialog('Помилка збереження: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- UI ---

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
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotosGallery(),
                      const SizedBox(height: 24),
                      _buildNameSection(),
                      const SizedBox(height: 24),
                      _buildLocationSection(),
                      const SizedBox(height: 24),
                      _buildBirthDateSection(),
                      const SizedBox(height: 24),
                      _buildBioSection(),
                      const SizedBox(height: 24),
                      _buildHobbiesSection(),
                      const SizedBox(height: 40),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Решта UI методів) ...

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Редагування профілю',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ваші фото', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            ..._existingPhotoUrls.map((url) => _buildPhotoItem(image: Image.network(url, fit: BoxFit.cover), onRemove: () => _removeExistingPhoto(url))),
            ..._newPhotoFiles.map((file) => _buildPhotoItem(image: Image.file(file, fit: BoxFit.cover), onRemove: () => _removeNewPhoto(file))),
            if ((_existingPhotoUrls.length + _newPhotoFiles.length) < 6)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100, height: 140,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[400]!)),
                  child: const Center(child: Icon(Icons.add, size: 40, color: Colors.grey)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoItem({required Widget image, required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(width: 100, height: 140, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: image)),
        Positioned(top: 4, right: 4, child: GestureDetector(onTap: onRemove, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
      ],
    );
  }

  Widget _buildNameSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ім\'я', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)), const SizedBox(height: 8), Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]), child: TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Введіть ваше ім\'я', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)), style: const TextStyle(fontSize: 16)))]);
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Місце знаходження', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
                child: TextField(controller: _locationController, decoration: const InputDecoration(hintText: 'Введіть місто', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)), style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _useGPSLocation,
              child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.location_on, color: Colors.white, size: 20)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBirthDateSection() {
    String dateText = _birthDate != null ? '${_birthDate!.day.toString().padLeft(2, '0')}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}' : 'Оберіть дату';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Дата народження', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)), const SizedBox(height: 8), GestureDetector(onTap: _selectDate, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(dateText, style: TextStyle(fontSize: 16, color: _birthDate != null ? Colors.black87 : Colors.grey[600])), const Icon(Icons.calendar_today, color: Colors.blue, size: 20)])))]);
  }

  Widget _buildBioSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Про себе', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)), const SizedBox(height: 8), Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]), child: TextField(controller: _bioController, maxLines: 4, decoration: const InputDecoration(hintText: 'Розкажіть про себе...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)), style: const TextStyle(fontSize: 16)))]);
  }

  Widget _buildHobbiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Хобі', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
          child: Column(
            children: [
              if (_selectedHobbies.isNotEmpty) ...[
                Padding(padding: const EdgeInsets.all(16), child: Wrap(spacing: 8, runSpacing: 8, children: _selectedHobbies.map((hobby) => _buildSelectedHobbyTag(hobby)).toList())),
                const Divider(height: 1),
              ],
              Padding(padding: const EdgeInsets.all(16), child: Container(decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: TextField(controller: _hobbySearchController ??= TextEditingController(), onChanged: _filterHobbies, decoration: const InputDecoration(hintText: 'Пошук хобі...', prefixIcon: Icon(Icons.search, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)), style: const TextStyle(fontSize: 16)))),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: _filteredHobbies.isEmpty && _hobbySearchQuery.isNotEmpty ? _buildNoResultsMessage() : ListView.builder(shrinkWrap: true, itemCount: _filteredHobbies.length, itemBuilder: (context, index) {
                  final hobby = _filteredHobbies[index];
                  final isSelected = _selectedHobbies.contains(hobby);
                  return ListTile(leading: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.blue : Colors.grey), title: Text(hobby, style: TextStyle(color: isSelected ? Colors.blue : Colors.black87, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)), onTap: () => setState(() { isSelected ? _selectedHobbies.remove(hobby) : (_selectedHobbies.length < 8 ? _selectedHobbies.add(hobby) : _showMaxHobbiesDialog()); }));
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedHobbyTag(String hobby) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(hobby, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blue)), const SizedBox(width: 4), GestureDetector(onTap: () => setState(() => _selectedHobbies.remove(hobby)), child: const Icon(Icons.close, size: 14, color: Colors.blue))]));
  }

  Widget _buildSaveButton() {
    return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isUploading ? null : _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: _isUploading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Зберегти зміни', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))));
  }

  // --- ДОПОМІЖНІ МЕТОДИ ---

  Future<void> _useGPSLocation() async {
    setState(() => _isUploading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorDialog('Потрібен дозвіл на геолокацію');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 🟢 Зберігаємо координати в змінні класу
      _latitude = position.latitude;
      _longitude = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality ?? '';
        String country = place.country ?? '';
        setState(() {
          _locationController.text = '$city, $country';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Місцезнаходження знайдено!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      _showErrorDialog('Не вдалося визначити місце: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showMaxHobbiesDialog() { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Обмеження'), content: const Text('Можна вибрати максимум 8 хобі'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))])); }
  void _filterHobbies(String query) { setState(() { _hobbySearchQuery = query.toLowerCase(); _filteredHobbies = query.isEmpty ? List.from(_availableHobbies) : _availableHobbies.where((hobby) => hobby.toLowerCase().contains(_hobbySearchQuery)).toList(); }); }
  Widget _buildNoResultsMessage() { return Container(padding: const EdgeInsets.all(20), child: Column(children: [Icon(Icons.search_off, size: 48, color: Colors.grey.shade400), const SizedBox(height: 12), Text('Хобі не знайдено', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade600)), const SizedBox(height: 8), Text('Спробуйте інший пошуковий запит', style: TextStyle(fontSize: 14, color: Colors.grey.shade500))])); }
  void _showErrorDialog(String message) { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Помилка'), content: Text(message), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))])); }
}