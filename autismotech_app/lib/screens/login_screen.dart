// lib/screens/login_screen.dart
import 'package:autismotech_app/constants/colors.dart';
import 'package:autismotech_app/constants/theme.dart';
import 'package:autismotech_app/screens/apiservice.dart';
import 'package:autismotech_app/screens/upload_screen.dart'; // Ensure this import is correct
import 'package:flutter/material.dart';
import 'package:autismotech_app/screens/global.dart' as globals;

// import '../theme/theme.dart';
// import '../theme/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // Show a loading indicator (optional)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final loginResponse = await ApiService.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // Dismiss the loading indicator
        Navigator.of(context).pop();

        // Save the user ID in the global variable
        globals.globalUserId = loginResponse.userId;
        print('Logged in successfully. Token: ${loginResponse.accessToken}');
        print('User ID saved globally: ${globals.globalUserId}');

        // Navigate to UploadScreen using MaterialPageRoute
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UploadScreen()),
        );
      } catch (e) {
        // Dismiss the loading indicator
        Navigator.of(context).pop();

        print("Login error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email TextField
              TextFormField(
                controller: _emailController,
                style: textStyle.copyWith(
                  fontSize: 18,
                  color: AppColors.darkBlue,
                ),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: textStyle.copyWith(
                    fontSize: 18,
                    color: AppColors.darkBlue,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password TextField
              TextFormField(
                controller: _passwordController,
                style: textStyle.copyWith(
                  fontSize: 18,
                  color: AppColors.darkBlue,
                ),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: textStyle.copyWith(
                    fontSize: 18,
                    color: AppColors.darkBlue,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Login Button
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, // text color
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Login',
                  style: textStyle.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Link to Register Screen
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text(
                  'Don\'t have an account? Register',
                  style: textStyle.copyWith(
                    color: AppColors.darkBlue,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
