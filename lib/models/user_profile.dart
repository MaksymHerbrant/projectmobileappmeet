class UserProfile {
  final String id;
  final String name;
  final int age;
  final String description;
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

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      description: json['description'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      location: json['location'] ?? '',
      hobbies: List<String>.from(json['hobbies'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'description': description,
      'photos': photos,
      'location': location,
      'hobbies': hobbies,
    };
  }
} 