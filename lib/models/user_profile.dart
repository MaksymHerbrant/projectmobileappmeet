class UserProfile {
  final String id;
  final String name;
  final int age;
  final String description; // У базі це колонка 'bio'
  final List<String> photos;
  final String location;
  final List<String> hobbies;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.description,
    required this.photos,
    required this.location,
    required this.hobbies,
  });

  // 🟢 ФАБРИЧНИЙ МЕТОД (Конвертує дані з бази Supabase у наш об'єкт)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // 1. Обчислюємо вік
    int calculatedAge = 18; // Дефолт
    if (map['birth_date'] != null) {
      try {
        final birthDate = DateTime.parse(map['birth_date']);
        final today = DateTime.now();
        calculatedAge = today.year - birthDate.year;
        if (today.month < birthDate.month || 
            (today.month == birthDate.month && today.day < birthDate.day)) {
          calculatedAge--;
        }
      } catch (e) {
        // Якщо дата крива, залишаємо 18
      }
    }
    final finalAge = map['age'] != null ? (map['age'] as int) : calculatedAge;

    return UserProfile(
      id: map['id']?.toString() ?? '',
      // 🔥 FIX: Шукаємо ім'я всюди. Спочатку full_name, якщо пусто - name, якщо пусто - заглушка
      name: map['full_name'] ?? map['name'] ?? 'Користувач',
      age: finalAge,
      description: map['bio'] ?? map['description'] ?? '',
      photos: map['photos'] != null 
          ? List<String>.from(map['photos']) 
          : [],
      location: map['location'] ?? 'Україна',
      hobbies: map['hobbies'] != null 
          ? List<String>.from(map['hobbies']) 
          : [],
    );
  }
  // Додай це всередину класу UserProfile
  factory UserProfile.empty() {
    return UserProfile(
      id: '',
      name: 'Невідомий',
      age: 0,
      description: '',
      photos: [],
      location: '',
      hobbies: [],
    );
  }
}