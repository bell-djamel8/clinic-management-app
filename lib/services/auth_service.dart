import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Traduit les erreurs Firebase en messages clairs en français
  String errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte ne correspond à cet e-mail';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Format d\'e-mail invalide';
      case 'too-many-requests':
        return 'Trop de tentatives, réessayez plus tard';
      default:
        return 'Une erreur est survenue : ${e.message}';
    }
  }
}
