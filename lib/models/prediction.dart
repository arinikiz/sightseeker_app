class Prediction {
  final String challengeId;
  final String challengeTitle;
  final int totalPredicted;
  final int currentCount;
  final int? userPrediction;
  final int predictorCount;

  Prediction({
    required this.challengeId,
    required this.challengeTitle,
    required this.totalPredicted,
    required this.currentCount,
    this.userPrediction,
    this.predictorCount = 0,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      challengeId: json['challengeId'] as String,
      challengeTitle: json['challengeTitle'] as String,
      totalPredicted: json['totalPredicted'] as int,
      currentCount: json['currentCount'] as int,
      userPrediction: json['userPrediction'] as int?,
      predictorCount: json['predictorCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'totalPredicted': totalPredicted,
      'currentCount': currentCount,
      'userPrediction': userPrediction,
      'predictorCount': predictorCount,
    };
  }
}
