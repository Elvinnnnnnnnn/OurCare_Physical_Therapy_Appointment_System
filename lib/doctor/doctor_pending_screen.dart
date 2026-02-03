import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorPendingScreen extends StatelessWidget {
  const DoctorPendingScreen({super.key});

  // 🎨 Brand colors (same style as your app)
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kGreyText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🔒 Disable back button
      child: Scaffold(
        backgroundColor: kWhite,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// ⏳ ICON CONTAINER
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kSoftBlue.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 56,
                      color: kDarkBlue,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// TITLE
                  const Text(
                    'Account Pending Approval',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kDarkBlue,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  const Text(
                    'Your doctor account has been created\n'
                    'and is currently under review.\n\n'
                    'Please wait for the administrator to activate your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: kGreyText,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// LOGOUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// FOOTER NOTE
                  const Text(
                    'You will be able to access your dashboard\nonce your account is approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
