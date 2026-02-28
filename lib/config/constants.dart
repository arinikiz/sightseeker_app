class AppConstants {
  // API
  static const String apiBaseUrl = 'https://YOUR_API_GATEWAY_URL';

  // Map defaults (Hong Kong center)
  static const double defaultLatitude = 22.3193;
  static const double defaultLongitude = 114.1694;
  static const double defaultZoom = 11.0;

  // AWS
  static const String awsRegion = 'us-east-1'; // Change to your Bedrock-available region
  static const String s3BucketName = 'hk-explorer-photos';

  // User levels
  static const Map<String, int> levels = {
    'Explorer': 0,
    'Adventurer': 500,
    'Local Legend': 1500,
  };

  // Challenge types
  static const String typePhoto = 'photo';
  static const String typeFood = 'food';
  static const String typeActivity = 'activity';

  // Difficulty
  static const String difficultyEasy = 'easy';
  static const String difficultyMedium = 'medium';
  static const String difficultyHard = 'hard';
}
