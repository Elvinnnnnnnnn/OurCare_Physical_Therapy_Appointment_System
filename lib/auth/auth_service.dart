import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

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
    required String phoneNumber,
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
        'phone': phoneNumber,
        'role': role,
        'doctorId': doctorId,
        'emailVerified': false,
        'phoneVerified': false,
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

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': user.displayName ?? '',
          'email': user.email,
          'phone': '',
          'role': 'customer',
          'phoneVerified': true,
          'disabled': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) return null;

      final OAuthCredential credential =
          FacebookAuthProvider.credential(result.accessToken!.token);

      final userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': user.displayName ?? '',
          'email': user.email,
          'phone': '',
          'role': 'customer',
          'phoneVerified': true,
          'disabled': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// ========= LOGOUT =========
  Future<void> logout() async {
    await _auth.signOut();
  }
}
