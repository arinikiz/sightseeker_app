class AppUser {
  final String id;
  final String name;
  final String? avatarUrl;
  int points;
  List<String> completedChallenges;
  List<String> badges;

  AppUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.points = 0,
    List<String>? completedChallenges,
    List<String>? badges,
  })  : completedChallenges = completedChallenges ?? [],
        badges = badges ?? [];

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      points: json['points'] as int? ?? 0,
      completedChallenges: List<String>.from(json['completedChallenges'] ?? []),
      badges: List<String>.from(json['badges'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'points': points,
      'completedChallenges': completedChallenges,
      'badges': badges,
    };
  }
}
