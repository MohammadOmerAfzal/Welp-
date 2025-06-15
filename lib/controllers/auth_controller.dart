import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/user_session.dart';
import '../models/user_model.dart' as app_models;
import '../controllers/user_controller.dart';

class AuthController {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final UserController _userController = UserController();

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

      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Signing in with Firebase');
      final fb_auth.UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      final fb_auth.User? user = userCredential.user;

      if (user == null) {
        print('❌ Firebase user is null');
        return 'null_user';
      }

      // Set session
      UserSession.userId = user.uid;
      UserSession.userName = user.displayName ?? 'User';
      UserSession.userEmail = user.email ?? 'email@example.com';

      print('👤 Authenticated: ${UserSession.userEmail}');

      final userRef = _dbRef.child('users').child(UserSession.userId);
      final userSnapshot = await userRef.get();

      if (!userSnapshot.exists) {
        print('🆕 New user — creating record');
        await userRef.set({
          'userId': UserSession.userId,
          'username': UserSession.userName,
          'email': UserSession.userEmail,
          'password': '',
          'reviews': {},
          'favorites': [],
          'businesses': 0,
          'isAdmin': false,
          'userType': 0,
        });
      } else {
        print('✅ Existing user found');
      }

      // ✅ FIXED: Use userId instead of username
      final app_models.User? userObject =
      await _userController.getUser(UserSession.userId);

      if (userObject == null) {
        print('❌ Could not retrieve user object from DB');
        return 'error';
      }

      UserSession.user = userObject;
      UserSession.isAdmin = userObject.isAdmin;
      UserSession.isOwner = userObject.userType == 1;

      final redirectRoute = userObject.isAdmin
          ? '/admin'
          : userObject.userType == 1
          ? '/owner'
          : '/home';

      print('🚀 Redirecting to $redirectRoute');
      return redirectRoute;

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

  fb_auth.User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
}
