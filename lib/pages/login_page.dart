import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:another_flushbar/flushbar.dart';

import 'package:kampus_kart/widgets/nav_rail.dart';

// Login Page of the App. 
// Users will open immediately into this page after the splash screen.

void showTopMessage(BuildContext context, String message, {Color? color, IconData? icon}) {
  Flushbar(
    message: message,
    backgroundColor: const Color.fromARGB(255, 45, 196, 138),
    duration: const Duration(seconds: 3),
    flushbarPosition: FlushbarPosition.TOP,
    borderRadius: BorderRadius.circular(10),
    margin: const EdgeInsets.all(8),
    animationDuration: const Duration(milliseconds: 300),
    icon: Icon(icon ?? Icons.check_circle_outline, color: Colors.white),
  ).show(context);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true; // Toggles between login/signup
  bool _obscurePassword = true; // For password visibilty

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Validate input before calling Firebase
  bool _validateInput() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showTopMessage(context, 'Email and password cannot be empty!');
      return false;
    }

    // Basic email format check
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      showTopMessage(context, 'Email and password invalid!');
      return false;
    }

    return true;
  }

  // LOGIN LOGIC
  Future<void> _login() async {
    if (!_validateInput()) return;
    
    setState(() => _isLoading = true);
    try {
      // Looks for user email & password in the database
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Shows small widget announcing Login
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyNavRail(
            showLogin: true,
          )
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // SIGN-UP LOGIC
  Future<void> _signUp() async {
    if (!_validateInput()) return;

    setState(() => _isLoading = true);
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users')
        .doc(cred.user!.uid)
        .set({
          'role': 'user',
          'userName': '',
          'email': cred.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyNavRail(
            showSignUp: true,
            initialIndex: 3,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // FORGOT PASSWORD LOGIC
  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      showTopMessage(context, 'Please enter your email first!');
    }
    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      showTopMessage(context, 'Password reset email sent!');
    } on FirebaseAuthException catch (e) {
      _showError(e);
    }
  }

  void _showError(FirebaseAuthException e) {
    print('FirebaseAuthException code: ${e.code}'); // DEBUG
    print('Message from Firebase: ${e.message}'); // DEBUG

    String message = 'An error occured.';
    switch (e.code) {
      case 'invalid-credential':
        message = 'Wrong Email or Password.';
      case 'email-already-in-use':
        message = 'Email already in use.';
      case 'weak-password':
        message = 'Password should be at least 6 characters.';
    }
    showTopMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo of the App
              Image.asset(
                'assets/images/logo.png',
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'Welcome Back!' : 'Create an Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Email Input
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  )
                ),
              ),
              const SizedBox(height: 20),

              // Password Input
              TextField(
                obscureText: _obscurePassword,
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  )
                ),
              ),
              const SizedBox(height: 10),

              // Forgot Password
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot Password?'),
                  )
                ),
              const SizedBox(height: 20),

              // Login or Sign-up Button 
              SizedBox(
                width: double.infinity,
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _isLogin ? _login : _signUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(10),
                      )
                    ),
                    child: Text(
                      _isLogin ? 'Login' : 'Sign Up',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ),
              const SizedBox(height: 30),

              // Toggle Between Login and Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin
                    ? "Don't have an account?"
                    : 'Already have an account?'),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'Sign Up' : 'Login'),
                  )
                ],
              )
            ],
          ),
        )
      ),
    );
  }
}
