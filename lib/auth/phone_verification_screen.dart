import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/customer/customer_home_tab.dart';
import 'login_screen.dart';
import 'dart:async';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends State<PhoneVerificationScreen> {

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  int? _resendToken;
  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;


  final otpController = TextEditingController();

  String verificationId = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    sendOtp();
  }

  Future<void> sendOtp() async {
    if (!_canResend && verificationId.isNotEmpty) return;

    await FirebaseAuth.instance.verifyPhoneNumber(
    phoneNumber: widget.phoneNumber,
    forceResendingToken: _resendToken,


    verificationCompleted: (credential) async {
final user = FirebaseAuth.instance.currentUser;

if (user != null) {
await user.linkWithCredential(credential);
}
},


    verificationFailed: (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error')),
      );
    },

    codeSent: (verId, resendToken) {
    setState(() {
    verificationId = verId;
    _resendToken = resendToken;
    });

    startTimer();
    },


    codeAutoRetrievalTimeout: (verId) {
      setState(() {
        verificationId = verId;
      });
    },


    );
  }

  void startTimer() {
  _timer?.cancel();

  setState(() {
  _secondsRemaining = 60;
  _canResend = false;
  });

  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  if (_secondsRemaining == 0) {
  timer.cancel();
  setState(() {
  _canResend = true;
  });
  } else {
  setState(() {
  _secondsRemaining--;
  });
  }
  });
  }

  Future verifyOtp() async {

    if (verificationId.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Session expired. Resend code')),
);
return;
}

if (otpController.text.isEmpty) return;

setState(() => isLoading = true);

try {
final credential = PhoneAuthProvider.credential(
verificationId: verificationId,
smsCode: otpController.text.trim(),
);

final user = FirebaseAuth.instance.currentUser;

if (user == null) {
throw Exception('User not logged in');
}

await user.linkWithCredential(credential);

final uid = user.uid;

await FirebaseFirestore.instance
.collection('users')
.doc(uid)
.set({
'phoneVerified': true,
}, SetOptions(merge: true));

await Future.delayed(const Duration(milliseconds: 500));

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Phone verified')),
);

Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const CustomerHomeTab()),
  (route) => false,
);


} on FirebaseAuthException catch (e) {
print('ERROR CODE: ${e.code}');
print('ERROR MESSAGE: ${e.message}');

String message = 'Invalid OTP';

if (e.code == 'invalid-verification-code') {
  message = 'Wrong code';
} else if (e.code == 'session-expired') {
  message = 'Code expired. Request new one';
} else if (e.code == 'credential-already-in-use') {
  message = 'Phone already linked to another account';
} else if (e.code == 'provider-already-linked') {
  message = 'Phone already verified';
}

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(message)),
);

} catch (e) {
print('UNKNOWN ERROR: $e');

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Something went wrong')),
);

}

setState(() => isLoading = false);
}

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async => false,
    child: Scaffold(
      backgroundColor: kWhite,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// ICON
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kSoftBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    size: 32,
                    color: kDarkBlue,
                  ),
                ),

                const SizedBox(height: 24),

                /// TITLE
                const Text(
                  'Verify your phone',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),

                const SizedBox(height: 8),

                /// SUBTEXT
                Text(
                  'Enter the code sent to\n${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 30),

                /// OTP FIELD
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    letterSpacing: 6,
                  ),
                  decoration: InputDecoration(
                    hintText: '------',
                    filled: true,
                    fillColor: const Color(0xFFF7F9FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// VERIFY BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : verifyOtp,
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Verify Code',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                /// RESEND
                TextButton(
                  onPressed: _canResend ? sendOtp : null,
                  child: Text(
                  _canResend
                  ? 'Resend Code'
                  : 'Resend in $_secondsRemaining s',
                  style: const TextStyle(color: kPrimaryBlue),
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
@override
void dispose() {
_timer?.cancel();
otpController.dispose();
super.dispose();
}

}