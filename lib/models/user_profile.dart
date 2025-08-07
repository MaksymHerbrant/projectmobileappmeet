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
} 