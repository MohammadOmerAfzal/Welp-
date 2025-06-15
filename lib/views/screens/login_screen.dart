import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    final result = await _authController.loginWithGoogleAndRedirectFlags();

    setState(() => _isLoading = false);

    if (result == 'cancelled' || result == 'null_user' || result == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please try again.')),
      );
    } else {
      Navigator.pushReplacementNamed(context, result!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text('Sign in with Google'),
          onPressed: _handleSignIn,
        ),
      ),
    );
  }
}