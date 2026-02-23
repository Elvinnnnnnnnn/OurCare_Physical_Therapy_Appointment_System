import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ===============================
  /// REGISTER USER (CUSTOMER / DOCTOR)
  /// ===============================
  Future<String?> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // 1️⃣ Create Firebase Auth account
      final cred = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      // ✅ SEND VERIFICATION EMAIL HERE
      final user = cred.user;
      await user?.sendEmailVerification();

      final uid = user!.uid;
      
      // 2️⃣ Check if this email already exists in doctors collection
      final doctorQuery = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      String role = 'customer';
      String? doctorId;

      // 3️⃣ IF doctor record exists → claim it
      if (doctorQuery.docs.isNotEmpty) {
        final doc = doctorQuery.docs.first;
        role = 'customer'; // always
        doctorId = null;

        // ✅ THIS MATCHES YOUR RULES EXACTLY
        await doc.reference.update({
          'userId': uid,
        });
      }

      // 4️⃣ Create users document
      await _firestore.collection('users').doc(uid).set({
        'fullName': fullName,
        'email': normalizedEmail,
        'role': role,
        'doctorId': doctorId,
        'disabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // ✅ SUCCESS
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// ========= LOGIN =========
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// ========= LOGOUT =========
  Future<void> logout() async {
    await _auth.signOut();
  }
}
