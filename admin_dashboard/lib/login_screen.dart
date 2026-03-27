import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  static const Color kSoftBlue = Color(0xFFB3EBF2);

  bool loading = false;
  String error = '';

  Future<void> login() async {
    setState(() {
      error = '';
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    /// CHECK EMPTY
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Email and password are required';
      });
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser!;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final phoneVerified = doc['phoneVerified'] ?? false;

      if (!phoneVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          error = 'Verify your phone first';
        });
        return;
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        error = 'User not found';
      } else if (e.code == 'wrong-password') {
        error = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        error = 'Invalid email';
      } else {
        error = 'Login failed';
      }
    }

      setState(() {
        loading = false;
      });
    }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    body: Stack(
  children: [

    /// BACKGROUND
    SizedBox.expand(
      child: Image.asset(
        'assets/background.png',
        fit: BoxFit.cover,
      ),
    ),

    Container(
        color: Colors.white.withOpacity(0.30),
      ),
     Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// LOGO
            Image.asset(
              'assets/logo.png',
              height: 300,
            ),

            const SizedBox(height: 16),

            /// TITLE
            const Text(
              'Admin Login',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            /// EMAIL
            TextField(
              controller: emailController,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).nextFocus();
              },
              decoration: InputDecoration(
                hintText: 'Email',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// PASSWORD
            TextField(
              controller: passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => login(),
              decoration: InputDecoration(
                hintText: 'Password',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: kSoftBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: loading ? null : login,
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(color: Colors.black),
                      ),
              ),
            ),

            const SizedBox(height: 10),

            /// ERROR
            if (error.isNotEmpty)
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      ),
    ),
  ]
    )
    
  );
}
}