class Event {
  final String id;
  final String title;
  final String location;
  final DateTime dateTime;
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

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toIso8601String()),
      photos: List<String>.from(json['photos'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      description: json['description'] ?? '',
      participantsCount: json['participantsCount'] ?? 0,
      isPrivate: json['isPrivate'] ?? false,
      privateLocation: json['privateLocation'],
      meetingPoint: json['meetingPoint'],
      additionalInfo: json['additionalInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'dateTime': dateTime.toIso8601String(),
      'photos': photos,
      'tags': tags,
      'description': description,
      'participantsCount': participantsCount,
      'isPrivate': isPrivate,
      'privateLocation': privateLocation,
      'meetingPoint': meetingPoint,
      'additionalInfo': additionalInfo,
    };
  }
} 