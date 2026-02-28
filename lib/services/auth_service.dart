class AuthService {
  // TODO: Implement AWS Cognito auth (or Firebase Auth)

  Future<bool> signIn(String email, String password) async {
    // TODO: Sign in user
    throw UnimplementedError();
  }

  Future<bool> signUp(String email, String password, String name) async {
    // TODO: Register new user
    throw UnimplementedError();
  }

  Future<void> signOut() async {
    // TODO: Sign out
    throw UnimplementedError();
  }

  Future<String?> getCurrentUserId() async {
    // TODO: Return current user ID or null
    throw UnimplementedError();
  }
}
