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

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      isTyping: json['isTyping'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isTyping': isTyping,
    };
  }
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

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'].toString(),
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhoto: json['userPhoto'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(json['lastMessageTime'] ?? DateTime.now().toIso8601String()),
      unreadCount: json['unreadCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      isTyping: json['isTyping'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'isTyping': isTyping,
    };
  }
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

  factory ActiveContact.fromJson(Map<String, dynamic> json) {
    return ActiveContact(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      photo: json['photo'] ?? '',
      hasNewStory: json['hasNewStory'] ?? false,
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo': photo,
      'hasNewStory': hasNewStory,
      'isOnline': isOnline,
    };
  }
} 