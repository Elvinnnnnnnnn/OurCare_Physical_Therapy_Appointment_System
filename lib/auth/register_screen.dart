import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_service.dart';
import 'login_screen.dart';
import 'phone_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;  

  // 🎨 Brand colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  /// 🔗 LINK DOCTOR RECORD (IMPORTANT)
  Future<void> _linkDoctorAccount(String email, String phoneNumber) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doctorQuery = await FirebaseFirestore.instance
        .collection('doctors')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    if (doctorQuery.docs.isEmpty) return;

    final doctorDoc = doctorQuery.docs.first;

    // link doctor → user
    await doctorDoc.reference.update({
      'userId': uid,
      'phone': phoneNumber,
    });

    // update user role
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'role': 'doctor',
      'doctorId': doctorDoc.id,
    });
  }

void _showTermsDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'OurCare Physical Therapy Clinic',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              const SizedBox(
                height: 350,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        'Last Updated: 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        '1. Acceptance of Terms',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'By using OurCare Physical Therapy Clinic, you agree to these terms.',
                      ),

                      SizedBox(height: 10),

                      Text(
                        '2. Service',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'We provide appointment booking services. Providers are responsible for their services.',
                      ),

                      SizedBox(height: 10),

                      Text(
                        '3. Accounts',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'You must provide accurate information and keep your account secure.',
                      ),

                      SizedBox(height: 10),

                      Text(
                        '4. Appointments',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Appointments depend on availability. Late arrivals may be cancelled.',
                      ),

                      SizedBox(height: 10),

                      Text(
                        '5. Payments',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Payments are processed via third parties. Prices may change.',
                      ),

                      SizedBox(height: 10),

                      Text(
                        '6. Cancellation',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Refunds depend on provider policies.',
                      ),

                      SizedBox(height: 10),

                      Text(
                        '7. Rescheduling Policy',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Reschedule at least 7 days before appointment. Late reschedule may incur a 30% fee.',
                      ),

                      SizedBox(height: 10),

                      Text(
                        '8. User Conduct',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Do not misuse the app or provide false information.',
                      ),

                      SizedBox(height: 10),

                      Text(
                        '9. Liability',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'We are not liable for provider services or system issues.',
                      ),

                      SizedBox(height: 10),

                      Text(
                        '10. Privacy',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Your data is handled according to our privacy policy.',
                      ),

                      SizedBox(height: 16),

                      Text(
                        'By using this app, you agree to these terms.',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),

                  const SizedBox(width: 8),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1562E2),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _acceptedTerms = true;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Agree'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the Terms and Conditions'),
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = AuthService();

    String raw = _phoneController.text.trim();

    if (raw.startsWith('0')) {
      raw = raw.substring(1);
    }

    final phone = '+63$raw';

    final error = await authService.registerUser(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phoneNumber: phone,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      // 🔗 LINK DOCTOR IF EXISTS
      await _linkDoctorAccount(
        _emailController.text.trim(),
        phone,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the OTP sent to your phone'),
        ),
      );

      _fullNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhoneVerificationScreen(
            phoneNumber: phone,
          ),
        ),
      );

      _phoneController.clear();
    }

    setState(() => _isLoading = false);
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: kSoftBlue.withOpacity(0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkBlue),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Center(
                  child: Image.asset(
                    'assets/clinic-logo.png',
                    height: 164,
                  ),
                ),

                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _fullNameController,
                  decoration: _inputStyle('Full Name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your name' : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: _inputStyle('Email'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter email' : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixText: '+63 ',
                    filled: true,
                    fillColor: kSoftBlue.withOpacity(0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter phone number';
                    if (v.length != 10) return 'Enter 10 digits';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputStyle('Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (v) =>
                      v != null && v.length < 6 ? 'Min 6 characters' : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: _inputStyle('Confirm Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showTermsDialog,
                        child: const Text(
                          'I agree to the Terms and Conditions',
                          style: TextStyle(
                            color: kPrimaryBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
