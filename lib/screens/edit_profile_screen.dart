import 'package:dating_app/l10n/gen/app_localizations.dart';
import '../l10n/interest_labels.dart';
import '../theme/app_theme.dart';
import '../theme/design_kit.dart';
import '../models/picked_photo.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../service/matches_service.dart';
import '../service/location_service.dart'; // 👇 ВАЖЛИВО: Імпорт для VectorUtils

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfileScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Клієнт Supabase
  final _supabase = Supabase.instance.client;
  final LocationService _locationService = LocationService();
  bool _isLocating = false;
  bool _hasSavedLocation = false;

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
  List<PickedPhoto> _newPhotoFiles = [];       
  bool _isUploading = false;            

  // Хобі
  List<String> _selectedHobbies = [];
  final List<String> _availableHobbies = [
    'Геймінг', 'Настільні ігри', 'Музика Lo-Fi', 'Похід з наметом',
    'Фентезі книги', 'Фотографія', 'Подорожі', 'Кулінарія',
    'Спорт', 'Читання', 'Музика', 'Танці', 'Малювання',
    'Програмування', 'Йога', 'Біг', 'Велоспорт', 'Плавання',
  ];

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
      final photo = await PickedPhoto.fromXFile(image);
      if (!mounted) return;
      setState(() => _newPhotoFiles.add(photo));
    }
  }

  void _removeExistingPhoto(String url) {
    setState(() {
      _existingPhotoUrls.remove(url);
    });
  }

  void _removeNewPhoto(PickedPhoto file) {
    setState(() {
      _newPhotoFiles.remove(file);
    });
  }

  Future<List<String>> _uploadNewPhotos() async {
    List<String> uploadedUrls = [];
    final userId = _supabase.auth.currentUser!.id;

    for (var i = 0; i < _newPhotoFiles.length; i++) {
      try {
        final photo = _newPhotoFiles[i];
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$i.${photo.extension}';
        final filePath = '$userId/$fileName';

        await _supabase.storage.from('avatars').uploadBinary(
          filePath,
          photo.bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: photo.mimeType,
          ),
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
            colorScheme: Theme.of(context).colorScheme,
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
    if (_nameController.text.trim().isEmpty) { _showErrorDialog(AppLocalizations.of(context)!.pr_enter_name); return; }
    if (_locationController.text.trim().isEmpty) { _showErrorDialog(AppLocalizations.of(context)!.pr_enter_location); return; }
    if (_birthDate == null) { _showErrorDialog(AppLocalizations.of(context)!.pr_need_birth); return; }

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

      // Координати пишемо не сюди, а через RPC нижче: прямий запис у
      // location_point залишав geo порожнім, а стрічка шукає саме за geo —
      // тобто людина ставала невидимою для пошуку поруч.

      await _supabase.from('profiles').update(updates).eq('id', userId);

      if (lat != 0 && long != 0) {
        await _supabase.rpc('update_my_location', params: {
          'p_lat': lat,
          'p_long': long,
        });
      }

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
          SnackBar(content: Text(AppLocalizations.of(context)!.pr_saved), backgroundColor: Theme.of(context).extension<AppSemantics>()!.success),
        );
      }
    } catch (e) {
      debugPrint("Full save error: $e");
      if (mounted) _showErrorDialog(AppLocalizations.of(context)!.pr_save_failed);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: Ds.background(context),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 6,
                    bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.pr_your_photos.toUpperCase(), style: Ds.label(context)),
                      const SizedBox(height: 8),
                      _buildPhotosGallery(),
                      const SizedBox(height: 16),
                      Text(t.pr_name.toUpperCase(), style: Ds.label(context)),
                      const SizedBox(height: 8),
                      DsTextField(controller: _nameController, hint: t.pr_enter_name),
                      const SizedBox(height: 16),
                      Text(t.pr_about.toUpperCase(), style: Ds.label(context)),
                      const SizedBox(height: 8),
                      _buildBioSection(),
                      const SizedBox(height: 16),
                      Text(t.pr_location.toUpperCase(), style: Ds.label(context)),
                      const SizedBox(height: 8),
                      _buildLocationSection(),
                      const SizedBox(height: 16),
                      Text(t.pr_birth_date.toUpperCase(), style: Ds.label(context)),
                      const SizedBox(height: 8),
                      _buildBirthDateSection(),
                      const SizedBox(height: 16),
                      Text(
                        // «інтереси · 4 з 8» — лічильник просто в підписі, як у макеті.
                        '${t.pr_hobbies} · ${_selectedHobbies.length} ${t.of_count(8)}'
                            .toUpperCase(),
                        style: Ds.label(context),
                      ),
                      const SizedBox(height: 10),
                      _buildHobbiesSection(),
                    ],
                  ),
                ),
              ),
              DsActionBar(
                child: DsButton(
                  label: t.pr_save_changes,
                  loading: _isUploading,
                  onPressed: _isUploading ? null : _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return DsTopBar(
      onBack: () => Navigator.of(context).pop(),
      title: AppLocalizations.of(context)!.pr_edit_title,
    );
  }

  /// Сітка фото за макетом: чотири колонки 3:4, скруглення 12,
  /// хрестик-кружечок 22 у куті, порожня комірка — пунктир із плюсом.
  Widget _buildPhotosGallery() {
    final tiles = <Widget>[
      ..._existingPhotoUrls.map((url) => _buildPhotoItem(
            image: Image.network(url, fit: BoxFit.cover),
            onRemove: () => _removeExistingPhoto(url),
          )),
      ..._newPhotoFiles.map((file) => _buildPhotoItem(
            image: Image.memory(file.bytes, fit: BoxFit.cover),
            onRemove: () => _removeNewPhoto(file),
          )),
      if ((_existingPhotoUrls.length + _newPhotoFiles.length) < 6)
        AspectRatio(
          aspectRatio: 3 / 4,
          child: DsAddTile(onTap: _pickImage, radius: 12),
        ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3 / 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles,
    );
  }

  Widget _buildPhotoItem({required Widget image, required VoidCallback onRemove}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 13,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// «Про мене»: поле на 90 із лічильником праворуч знизу, як у макеті.
  Widget _buildBioSection() {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 90),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(Ds.rField),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: TextField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 300,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: 15, height: 1.5, color: scheme.onSurface),
            cursorColor: scheme.primary,
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintText: AppLocalizations.of(context)!.pr_about_hint,
              hintStyle: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('${_bioController.text.length} / 300', style: Ds.tiny(context)),
      ],
    );
  }

  /// «Місто»: поле зі шпилькою і чипом «Оновити», що бере локацію з GPS.
  Widget _buildLocationSection() {
    final t = AppLocalizations.of(context)!;

    return DsTextField(
      controller: _locationController,
      hint: t.pr_enter_city,
      icon: Icons.place_outlined,
      suffix: _isLocating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : DsChip(
              label: t.pr_update_location,
              small: true,
              selected: true,
              onTap: _useGPSLocation,
            ),
    );
  }

  Widget _buildBirthDateSection() {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final hasDate = _birthDate != null;
    final dateText = hasDate
        ? '${_birthDate!.day.toString().padLeft(2, '0')}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}'
        : t.pr_pick_birth;

    return DsFieldBox(
      onTap: _selectDate,
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            dateText,
            style: TextStyle(
              fontSize: 16,
              // Колір із теми, а не Colors.black87 — на темній темі дата
              // була просто невидимою.
              color: hasDate ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Інтереси одним полем чипів, як у макеті: обрані залиті, тап перемикає.
  /// Пошук і список із кружечками прибрані — на вісімнадцяти пунктах чипи
  /// швидші й показують обране та доступне разом.
  Widget _buildHobbiesSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final hobby in _availableHobbies)
          DsChip(
            label: InterestLabels.of(context, hobby),
            small: true,
            selected: _selectedHobbies.contains(hobby),
            onTap: () => setState(() {
              if (_selectedHobbies.contains(hobby)) {
                _selectedHobbies.remove(hobby);
              } else if (_selectedHobbies.length < 8) {
                _selectedHobbies.add(hobby);
              } else {
                _showMaxHobbiesDialog();
              }
            }),
          ),
      ],
    );
  }

  // --- ДОПОМІЖНІ МЕТОДИ ---

  /// Визначає позицію, зберігає її на сервері й підставляє назву міста.
  ///
  /// Розрізняє причини відмови: вимкнена геолокація, відхилений дозвіл і
  /// відхилений назавжди — в останньому випадку система більше не питатиме,
  /// тож єдиний вихід це налаштування телефона.
  Future<void> _useGPSLocation() async {
    setState(() => _isLocating = true);
    try {
      final outcome = await _locationService.refreshMyLocation();

      if (!mounted) return;

      if (!outcome.isSuccess) {
        _showLocationProblem(outcome);
        return;
      }

      _hasSavedLocation = true;

      final coords = await _locationService.myCoordinates();
      if (coords != null) {
        _latitude = coords.lat;
        _longitude = coords.long;

        try {
          final placemarks =
              await placemarkFromCoordinates(coords.lat, coords.long);
          if (placemarks.isNotEmpty && mounted) {
            final place = placemarks.first;
            final city = place.locality ?? '';
            final country = place.country ?? '';
            final label = [city, country].where((e) => e.isNotEmpty).join(', ');
            if (label.isNotEmpty) {
              setState(() => _locationController.text = label);
            }
          }
        } catch (_) {
          // Назва міста — приємний бонус. Координати вже збережені, і саме
          // вони визначають, кого ви побачите у стрічці.
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(outcome.localized(context)),
          backgroundColor: Theme.of(context).extension<AppSemantics>()!.success,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showLocationProblem(LocationOutcome outcome) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.localized(context)),
        duration: const Duration(seconds: 6),
        action: outcome.needsSettings
            ? SnackBarAction(
                label: AppLocalizations.of(context)!.settings_button,
                textColor: Colors.white,
                onPressed: () => outcome == LocationOutcome.serviceDisabled
                    ? _locationService.openLocationSettings()
                    : _locationService.openSettings(),
              )
            : null,
      ),
    );
  }

  void _showMaxHobbiesDialog() { showDialog(context: context, builder: (context) => AlertDialog(title: Text(AppLocalizations.of(context)!.pr_limit), content: Text(AppLocalizations.of(context)!.pr_max_hobbies), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))])); }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
}
