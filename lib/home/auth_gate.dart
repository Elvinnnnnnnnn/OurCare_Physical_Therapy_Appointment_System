import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/welcome_screen.dart';
import '../customer/customer_home.dart';
import '../doctor/doctor_home.dart';
import '../doctor/doctor_pending_screen.dart';
import '../admin/admin_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // ⏳ AUTH LOADING
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🚪 NOT LOGGED IN
        if (!authSnapshot.hasData) {
          return const WelcomeScreen();
        }

        final user = authSnapshot.data!;

        // 🔒 BLOCK BACK BUTTON WHEN LOGGED IN
        return WillPopScope(
          onWillPop: () async => false,
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              // ⏳ USER DOC LOADING
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // 🚨 USER DOC MISSING (SAFETY)
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Setting up your account...'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;

              // 🚫 BLOCK DISABLED USERS
              if (userData['disabled'] == true) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.block, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Account Disabled',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Your account has been disabled.\nPlease contact the administrator.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final role = userData['role'];

              // 🎭 ROLE ROUTING
              switch (role) {
                case 'admin':
                  return AdminHomeScreen();

                case 'customer':
                  return const CustomerHome();

                case 'doctor':
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('doctors')
                        .where('userId', isEqualTo: user.uid)
                        .limit(1)
                        .snapshots(),
                    builder: (context, doctorSnap) {
                      if (!doctorSnap.hasData ||
                          doctorSnap.data!.docs.isEmpty) {
                        // ⏳ Doctor exists but not linked/activated
                        return const DoctorPendingScreen();
                      }

                      final doctorData =
                          doctorSnap.data!.docs.first.data()
                              as Map<String, dynamic>;

                      // 🚫 NOT ACTIVATED
                      if (doctorData['activated'] != true) {
                        return const DoctorPendingScreen();
                      }

                      // ✅ ACTIVATED
                      return const DoctorHome();
                    },
                  );

                default:
                  return const Scaffold(
                    body: Center(child: Text('Invalid role')),
                  );
              }
            },
          ),
        );
      },
    );
  }
}
