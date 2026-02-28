import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/challenge_detail_screen.dart';
import '../screens/challenge_review_screen.dart';
import '../screens/leaderboard_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String challengeDetail = '/challenge-detail';
  static const String challengeComplete = '/challenge-complete';
  static const String challengeReview = '/challenge-review';
  static const String leaderboard = '/leaderboard';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      auth: (context) => const AuthScreen(),
      home: (context) => const HomeScreen(),
      leaderboard: (context) => const LeaderboardScreen(),
      challengeDetail: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return ChallengeDetailScreen(
          placeId: args is String ? args : null,
        );
      },
      challengeReview: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final challengeId = args?['challengeId'] as String? ?? '';
        final challengeTitle = args?['challengeTitle'] as String? ?? 'Challenge';
        return ChallengeReviewScreen(
          challengeId: challengeId,
          challengeTitle: challengeTitle,
        );
      },
    };
  }
}
