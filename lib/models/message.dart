class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool isTyping;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.isTyping = false,
  });
}

class ChatConversation {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
  });
}

class ActiveContact {
  final String id;
  final String name;
  final String photo;
  final bool hasNewStory;
  final bool isOnline;

  ActiveContact({
    required this.id,
    required this.name,
    required this.photo,
    this.hasNewStory = false,
    this.isOnline = false,
  });
} 