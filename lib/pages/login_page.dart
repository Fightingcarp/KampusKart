import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kampus_kart/widgets/nav_rail.dart';

// Login Page of the App. 
// Users will open immediately into this page after the splash screen.

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password cannot be empty')),
      );
      return false;
    }

    // Basic email format check
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Succesful!'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyNavRail())
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
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account Created! You are now logged in.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyNavRail())
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first!')),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e);
    }
  }

  void _showError(FirebaseAuthException e) {
    String message = 'An error occured.';
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found for that email.';
      case 'wrong-password':
        message = 'Wrong password.';
      case 'email-already-in-use':
        message = 'Email already in use.';
      case 'invalid-email':
        message = 'Invalid email format.';
      case 'weak-password':
        message = 'Password should be at least 6 characters.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
