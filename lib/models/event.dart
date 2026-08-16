class Event {
  final String id;
  final String title;
  final String location;
  final DateTime dateTime; // У базі це 'event_date'
  final List<String> photos;
  final List<String> tags;
  final String description;
  final int participantsCount;
  final bool isPrivate;
  final String? privateLocation;
  final String? meetingPoint;
  final String? additionalInfo;

  Event({
    required this.id,
    required this.title,
    required this.location,
    required this.dateTime,
    required this.photos,
    required this.tags,
    required this.description,
    required this.participantsCount,
    this.isPrivate = false,
    this.privateLocation,
    this.meetingPoint,
    this.additionalInfo,
  });

  // 🟢 ФАБРИЧНИЙ МЕТОД для подій
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'].toString(),
      title: map['title'] ?? 'Без назви',
      location: map['location'] ?? 'Онлайн',
      // Парсимо дату з рядка ISO 8601
      dateTime: map['event_date'] != null 
          ? DateTime.parse(map['event_date']) 
          : DateTime.now(),
      photos: map['photos'] != null 
          ? List<String>.from(map['photos']) 
          : [],
      tags: map['tags'] != null 
          ? List<String>.from(map['tags']) 
          : [],
      description: map['description'] ?? '',
      // Поки ставимо 0 або беремо з бази, якщо додав колонку participants_count
      participantsCount: map['participants_count'] ?? 0, 
      isPrivate: map['is_private'] ?? false,
      // Додаткові поля (якщо вони є в базі, інакше null)
      privateLocation: map['private_location'],
      meetingPoint: map['meeting_point'],
      additionalInfo: map['additional_info'],
    );
  }
}