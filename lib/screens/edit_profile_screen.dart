import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfileScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  TextEditingController? _hobbySearchController;
  
  List<String> _selectedHobbies = [];
  List<String> _availableHobbies = [
    'Геймінг',
    'Настільні ігри',
    'Музика Lo-Fi',
    'Похід з наметом',
    'Фентезі книги',
    'Фотографія',
    'Подорожі',
    'Кулінарія',
    'Спорт',
    'Читання',
    'Музика',
    'Танці',
    'Малювання',
    'Програмування',
    'Йога',
    'Біг',
    'Велоспорт',
    'Плавання',
  ];
  
  List<String> _filteredHobbies = [];
  String _hobbySearchQuery = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileData['name'] ?? '');
    _locationController = TextEditingController(text: widget.profileData['location'] ?? '');
    _bioController = TextEditingController(text: widget.profileData['aboutMe'] ?? '');
    _ageController = TextEditingController(text: (widget.profileData['age'] ?? '').toString());
    _hobbySearchController = TextEditingController();
    
    // Ініціалізуємо вибрані хобі
    if (widget.profileData['hobbies'] != null) {
      _selectedHobbies = List<String>.from(widget.profileData['hobbies']);
    }
    
    // Ініціалізуємо відфільтровані хобі
    _filteredHobbies = List.from(_availableHobbies);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _hobbySearchController?.dispose();
    super.dispose();
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
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameSection(),
                      const SizedBox(height: 24),
                      _buildLocationSection(),
                      const SizedBox(height: 24),
                      _buildAgeSection(),
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ім\'я',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Введіть ваше ім\'я',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Місце знаходження',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'Введіть місто або використайте GPS',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _useGPSLocation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Вік',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Введіть ваш вік',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Про себе',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Розкажіть про себе...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildHobbiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Хобі',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Вибрані хобі
              if (_selectedHobbies.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedHobbies.map((hobby) => _buildSelectedHobbyTag(hobby)).toList(),
                  ),
                ),
                const Divider(height: 1),
              ],
              // Пошук хобі
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _hobbySearchController ??= TextEditingController(),
                    onChanged: _filterHobbies,
                    decoration: const InputDecoration(
                      hintText: 'Пошук хобі...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              // Список доступних хобі
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: _filteredHobbies.isEmpty && _hobbySearchQuery.isNotEmpty
                    ? _buildNoResultsMessage()
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredHobbies.length,
                        itemBuilder: (context, index) {
                          final hobby = _filteredHobbies[index];
                          final isSelected = _selectedHobbies.contains(hobby);
                          
                          return ListTile(
                            leading: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            title: Text(
                              hobby,
                              style: TextStyle(
                                color: isSelected ? Colors.blue : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedHobbies.remove(hobby);
                                } else {
                                  if (_selectedHobbies.length < 8) {
                                    _selectedHobbies.add(hobby);
                                  } else {
                                    _showMaxHobbiesDialog();
                                  }
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedHobbyTag(String hobby) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hobby,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedHobbies.remove(hobby);
              });
            },
            child: const Icon(
              Icons.close,
              size: 14,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Зберегти зміни',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _useGPSLocation() {
    // Симуляція отримання GPS координат
    setState(() {
      _locationController.text = 'Київ, Україна';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Місцезнаходження оновлено'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showMaxHobbiesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обмеження'),
        content: const Text('Можна вибрати максимум 8 хобі'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    // Валідація
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Введіть ваше ім\'я');
      return;
    }
    
    if (_locationController.text.trim().isEmpty) {
      _showErrorDialog('Введіть місце знаходження');
      return;
    }
    
    if (_ageController.text.trim().isEmpty) {
      _showErrorDialog('Введіть ваш вік');
      return;
    }
    
    final age = int.tryParse(_ageController.text);
    if (age == null || age < 18 || age > 100) {
      _showErrorDialog('Введіть коректний вік (18-100)');
      return;
    }

    // Повертаємо оновлені дані
    final updatedData = {
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'age': age,
      'aboutMe': _bioController.text.trim(),
      'hobbies': _selectedHobbies,
    };

    Navigator.of(context).pop(updatedData);
  }

  void _filterHobbies(String query) {
    setState(() {
      _hobbySearchQuery = query.toLowerCase();
      if (query.isEmpty) {
        _filteredHobbies = List.from(_availableHobbies);
      } else {
        _filteredHobbies = _availableHobbies
            .where((hobby) => hobby.toLowerCase().contains(_hobbySearchQuery))
            .toList();
      }
    });
  }

  Widget _buildNoResultsMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Хобі не знайдено',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Спробуйте інший пошуковий запит',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Помилка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 