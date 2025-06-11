import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        currentUserId = user.uid;
        currentUserName = user.displayName ?? 'User';
        currentUserEmail = user.email ?? 'email@example.com';
      }

      return user;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  /// Sign out from Firebase & Google
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Sign-out error: $e');
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if signed in
  bool get isSignedIn => _auth.currentUser != null;
}
