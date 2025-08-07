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
} 