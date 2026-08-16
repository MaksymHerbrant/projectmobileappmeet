class SupabaseProfile {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SupabaseProfile({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });

  factory SupabaseProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return SupabaseProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'bio': bio,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SupabaseProfile copyWith({
    String? username,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? bio,
  }) {
    return SupabaseProfile(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

