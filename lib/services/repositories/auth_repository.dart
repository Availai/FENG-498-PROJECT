import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({required FirebaseAuth firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final cleanDisplayName = displayName?.trim();
    if (cleanDisplayName != null && cleanDisplayName.isNotEmpty) {
      await credential.user?.updateDisplayName(cleanDisplayName);
    }
  }

  Future<void> signInAnonymously() {
    return _firebaseAuth.signInAnonymously();
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }
}
