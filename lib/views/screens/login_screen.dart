import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../main.dart';

class LoginScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      print('➡️ Starting Google sign-in');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print('❌ Google sign-in cancelled by user');
        return;
      }

      print('✅ Google user selected: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Signing in with Firebase');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
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
          });
          isAdmin = false;
        } else {
          print('✅ User exists in DB');
          final data = userSnapshot.value as Map<dynamic, dynamic>?;
          isAdmin = data?['isAdmin'] == true;
        }

        print('🚀 Redirecting to ${isAdmin ? '/admin' : '/home'}');
        Navigator.pushReplacementNamed(context, isAdmin ? '/admin' : '/home');
      } else {
        print('❌ Firebase user is null');
      }
    } catch (e) {
      print('❌ Exception during sign-in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text('Sign in with Google'),
          onPressed: () => _signInWithGoogle(context),
        ),
      ),
    );
  }
}
