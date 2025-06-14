import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import '../main.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<String?> loginWithGoogleAndRedirectFlags() async {
    try {
      print('➡️ Starting Google sign-in');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ Google sign-in cancelled by user');
        return 'cancelled';
      }

      print('✅ Google user selected: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Signing in with Firebase');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        print('❌ Firebase user is null');
        return 'null_user';
      }

      currentUserId = user.uid;
      currentUserName = user.displayName ?? 'User';
      currentUserEmail = user.email ?? 'email@example.com';

      print('👤 User authenticated: $currentUserEmail');

      final userRef = _dbRef.child('users').child(currentUserId);
      final userSnapshot = await userRef.get();

      print('📡 Checking DB entry...');

      if (!userSnapshot.exists) {
        print('🆕 New user — creating DB record');
        await userRef.set({
          'name': currentUserName,
          'email': currentUserEmail,
          'isAdmin': false,
          'isOwner': false,
        });
        isAdmin = false;
        isOwner = false;
      } else {
        print('✅ User exists in DB');
        final data = userSnapshot.value as Map<dynamic, dynamic>?;
        isAdmin = data?['isAdmin'] == true;
        isOwner = data?['isOwner'] == true;
      }

      print('🚀 Redirecting to ${isAdmin ? '/admin' : isOwner ? '/owner' : '/home'}');
      if (isAdmin) return '/admin';
      if (isOwner) return '/owner';
      return '/home';
    } catch (e) {
      print('❌ Exception during sign-in: $e');
      return 'error';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      print('🔓 User signed out');
    } catch (e) {
      print('❌ Sign-out error: $e');
    }
  }

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
}
