class Participant {
  final String userId;
  final String name;
  final String? avatarUrl;
  final String status; // going, completed, planning
  final String? plannedTime;

  Participant({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.status,
    this.plannedTime,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String,
      plannedTime: json['plannedTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'status': status,
      'plannedTime': plannedTime,
    };
  }
}
