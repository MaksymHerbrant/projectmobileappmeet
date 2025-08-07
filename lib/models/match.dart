class Match {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final bool isMutual;
  final String? message;
  final MatchStatus status;

  Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.isMutual,
    this.message,
    required this.status,
  });
}

enum MatchStatus {
  pending,    // Очікує відповіді
  accepted,   // Прийнято
  rejected,   // Відхилено
  mutual,     // Взаємний лайк
} 