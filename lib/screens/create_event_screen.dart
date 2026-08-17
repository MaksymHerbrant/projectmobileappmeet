import '../models/picked_photo.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import '../service/matches_service.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> with TickerProviderStateMixin {
  final _matchesService = MatchesService();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Контролери анімації
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Контролери форми
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  
  // Контролери для приватної події
  final _privateLocationController = TextEditingController();
  final _meetingPointController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _privateMessageController = TextEditingController();

  // Стан форми
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isPrivateEvent = false;
  bool _isLoading = false;
  List<String> _selectedTags = [];
  
  // Локальні фотографії
  final ImagePicker _picker = ImagePicker();
  List<PickedPhoto> _selectedLocalPhotos = [];

  final List<String> _availableTags = [
    'Музика', 'Танці', 'Спорт', 'Подорожі', 'Освіта', 'Вечірка',
    'Кава', 'Кіно', 'Мистецтво', 'Походи', 'Гори', 'Природа',
    'IT', 'Програмування', 'Геймінг', 'Фотографія', 'Кулінарія'
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _maxParticipantsController.text = '10'; // Значення за замовчуванням
  }

  void _initAnimations() {
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack)
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _privateLocationController.dispose();
    _meetingPointController.dispose();
    _additionalInfoController.dispose();
    _privateMessageController.dispose();
    super.dispose();
  }

  // 🟢 Метод вибору фото з галереї
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Оптимізація розміру
        maxWidth: 1080,
        maxHeight: 1920,
      );
      
      if (image != null) {
        final photo = await PickedPhoto.fromXFile(image);
        if (!mounted) return;
        setState(() => _selectedLocalPhotos.add(photo));
      }
    } catch (e) {
      debugPrint("Помилка вибору фото: $e");
    }
  }

  // 🟢 Метод видалення фото
  void _removePhoto(int index) {
    setState(() {
      _selectedLocalPhotos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildAppBar(t),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(t),
                          const SizedBox(height: 24),
                          _buildBasicInfoSection(t),
                          const SizedBox(height: 24),
                          _buildDateTimeSection(t),
                          const SizedBox(height: 24),
                          _buildPrivateEventSection(t),
                          if (_isPrivateEvent) ...[
                            const SizedBox(height: 20),
                            _buildPrivateEventFields(t),
                          ],
                          const SizedBox(height: 24),
                          _buildTagsSection(t),
                          const SizedBox(height: 24),
                          _buildPhotosSection(t),
                          const SizedBox(height: 32),
                          _buildCreateButton(t),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            t.create_event,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Створимо щось особливе ✨',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Заповніть інформацію про вашу подію, щоб інші могли приєднатись',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(AppLocalizations t) {
    return _buildSection(
      title: 'Основна інформація',
      icon: Icons.info_outline,
      children: [
        _buildTextField(
          controller: _titleController,
          label: 'Назва події',
          hint: 'Наприклад: Вечірка у центрі міста',
          icon: Icons.title,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Введіть назву події';
            if (value!.length < 3) return 'Назва повинна містити мінімум 3 символи';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Опис події',
          hint: 'Розкажіть детальніше про вашу подію...',
          icon: Icons.description,
          maxLines: 3,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Додайте опис події';
            if (value!.length < 10) return 'Опис повинен містити мінімум 10 символів';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _locationController,
          label: 'Загальна локація',
          hint: 'Район або загальна область',
          icon: Icons.location_on,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Вкажіть локацію';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _maxParticipantsController,
          label: 'Максимальна кількість учасників',
          hint: '10',
          icon: Icons.people,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Вкажіть кількість учасників';
            final num = int.tryParse(value!);
            if (num == null || num < 2) return 'Мінімум 2 учасники';
            if (num > 100) return 'Максимум 100 учасників';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(AppLocalizations t) {
    return _buildSection(
      title: 'Дата та час',
      icon: Icons.schedule,
      children: [
        Row(
          children: [
            Expanded(child: _buildDateSelector(t)),
            const SizedBox(width: 16),
            Expanded(child: _buildTimeSelector(t)),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector(AppLocalizations t) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedDate == null ? Colors.grey.shade300 : Colors.purple.shade300,
            width: 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: _selectedDate == null ? Colors.grey.shade400 : Colors.purple.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Дата', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    _selectedDate == null ? 'Оберіть дату' : DateFormat('dd.MM.yyyy').format(_selectedDate!),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _selectedDate == null ? Colors.grey.shade400 : Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(AppLocalizations t) {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedTime == null ? Colors.grey.shade300 : Colors.purple.shade300,
            width: 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: _selectedTime == null ? Colors.grey.shade400 : Colors.purple.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Час', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    _selectedTime == null ? 'Оберіть час' : _selectedTime!.format(context),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _selectedTime == null ? Colors.grey.shade400 : Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateEventSection(AppLocalizations t) {
    return _buildSection(
      title: 'Тип події',
      icon: Icons.security,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isPrivateEvent ? Colors.purple.shade300 : Colors.grey.shade300, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isPrivateEvent ? Colors.purple.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isPrivateEvent ? Icons.lock : Icons.public,
                  color: _isPrivateEvent ? Colors.purple.shade600 : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isPrivateEvent ? 'Приватна вечірка' : 'Публічна подія', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(
                      _isPrivateEvent ? 'Додаткова інформація буде доступна тільки запрошеним' : 'Подія доступна всім користувачам',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.3),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.2,
                child: Switch(
                  value: _isPrivateEvent,
                  onChanged: (value) {
                    setState(() => _isPrivateEvent = value);
                    if (value) _scrollToPrivateFields();
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.purple.shade400,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateEventFields(AppLocalizations t) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: _buildSection(
        title: 'Приватна інформація',
        icon: Icons.lock_outline,
        color: Colors.purple.shade50,
        children: [
          Text('Ця інформація буде доступна тільки після підтвердження запиту на участь', style: TextStyle(fontSize: 14, color: Colors.purple.shade700, fontStyle: FontStyle.italic, height: 1.4)),
          const SizedBox(height: 16),
          _buildTextField(controller: _privateLocationController, label: 'Точна адреса', hint: 'вул. Хрещатик, 1, кв. 10', icon: Icons.home, validator: _isPrivateEvent ? (v) => v?.isEmpty ?? true ? 'Вкажіть точну адресу' : null : null),
          const SizedBox(height: 16),
          _buildTextField(controller: _meetingPointController, label: 'Місце зустрічі', hint: 'Біля головного входу в ТРЦ', icon: Icons.meeting_room),
          const SizedBox(height: 16),
          _buildTextField(controller: _additionalInfoController, label: 'Додаткова інформація', hint: 'Що потрібно взяти з собою, дрес-код тощо', icon: Icons.info, maxLines: 2),
          const SizedBox(height: 16),
          _buildTextField(controller: _privateMessageController, label: 'Повідомлення для учасників', hint: 'Особисте повідомлення, яке побачать запрошені', icon: Icons.message, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildTagsSection(AppLocalizations t) {
    return _buildSection(
      title: 'Теги',
      icon: Icons.tag,
      children: [
        Text('Оберіть теги, які найкраще описують вашу подію (до 5)', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => _toggleTag(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purple.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.purple.shade300 : Colors.grey.shade300, width: 1.5),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[Icon(Icons.check_circle, size: 16, color: Colors.purple.shade600), const SizedBox(width: 4)],
                    Text(tag, style: TextStyle(color: isSelected ? Colors.purple.shade700 : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 🟢 ОНОВЛЕНА СЕКЦІЯ ФОТОГРАФІЙ 
  Widget _buildPhotosSection(AppLocalizations t) {
    return _buildSection(
      title: 'Фотографії',
      icon: Icons.photo_camera,
      children: [
        Text(
          'Додайте власні фото з галереї (до 5 штук)',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedLocalPhotos.length < 5 ? _selectedLocalPhotos.length + 1 : 5,
            itemBuilder: (context, index) {
              
              if (index == _selectedLocalPhotos.length) {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple.shade200, style: BorderStyle.solid, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.purple.shade400, size: 32),
                        const SizedBox(height: 8),
                        Text('Додати', style: TextStyle(color: Colors.purple.shade600, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: MemoryImage(_selectedLocalPhotos[index].bytes),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.purple.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.purple.shade400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.purple.shade400, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: TextStyle(color: Colors.purple.shade600),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildCreateButton(AppLocalizations t) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade600,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.purple.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, size: 24),
                  const SizedBox(width: 8),
                  Text(t.create_event, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.purple.shade600, onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.purple.shade600, onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else if (_selectedTags.length < 5) {
        _selectedTags.add(tag);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Можна обрати максимум 5 тегів'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }

  void _scrollToPrivateFields() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // 🟢 🟢 ОНОВЛЕНА ЛОГІКА СТВОРЕННЯ ПОДІЇ ТА ЗАВАНТАЖЕННЯ ФОТО
  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Будь ласка, заповніть всі обов\'язкові поля');
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      _showErrorSnackBar('Оберіть дату та час події');
      return;
    }

    if (_selectedLocalPhotos.isEmpty) {
      _showErrorSnackBar('Оберіть принаймні одне фото');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> uploadedPhotoUrls = [];
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      for (var i = 0; i < _selectedLocalPhotos.length; i++) {
        final photo = _selectedLocalPhotos[i];
        // Тека користувача — обов'язкова: політика сховища дозволяє запис лише
        // в теку, названу власним uid. Індекс у назві не дає двом фото
        // затерти одне одного в межах тієї ж мілісекунди.
        final filePath =
            '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.${photo.extension}';

        await supabase.storage.from('event_photos').uploadBinary(
              filePath,
              photo.bytes,
              fileOptions: FileOptions(contentType: photo.mimeType),
            );

        final imageUrl = supabase.storage.from('event_photos').getPublicUrl(filePath);
        uploadedPhotoUrls.add(imageUrl);
      }

      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final event = Event(
        id: '', // Supabase сам згенерує ID
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        dateTime: eventDateTime,
        photos: uploadedPhotoUrls, // Передаємо URL-адреси з Supabase
        tags: _selectedTags,
        participantsCount: int.tryParse(_maxParticipantsController.text) ?? 10,
        isPrivate: _isPrivateEvent,
        privateLocation: _isPrivateEvent ? _privateLocationController.text.trim() : null,
        meetingPoint: _isPrivateEvent && _meetingPointController.text.isNotEmpty 
            ? _meetingPointController.text.trim() : null,
        additionalInfo: _isPrivateEvent && _additionalInfoController.text.isNotEmpty 
            ? _additionalInfoController.text.trim() : null,
      );

      await _matchesService.createEvent(event);

      if (mounted) {
        Navigator.of(context).pop(event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Подію "${event.title}" успішно створено! 🎉'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error creating event: $e");
      if (mounted) {
        _showErrorSnackBar('Помилка при створенні події. Спробуйте ще раз.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}