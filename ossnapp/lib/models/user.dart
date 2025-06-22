class User {
  final String id;
  final String name;
  final String? avatarUrl;
  final String bio;

  User({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio = '',
  });
}