class EventLike {
  final String id;
  final String eventId;
  final String userId;
  final DateTime createdAt;
  final String? message;
  final EventLikeStatus status;

  EventLike({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.createdAt,
    this.message,
    required this.status,
  });
}

enum EventLikeStatus {
  pending,    // Очікує відповіді організатора
  accepted,   // Прийнято організатором
  rejected,   // Відхилено організатором
} 