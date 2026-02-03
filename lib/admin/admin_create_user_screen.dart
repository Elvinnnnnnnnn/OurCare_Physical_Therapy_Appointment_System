import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  State<AdminCreateUserScreen> createState() =>
      _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  // 🎨 SAME ADMIN COLORS (MATCH ADD DOCTOR)
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kGreyText = Color(0xFF6B7280);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 12,
        color: kGreyText,
      ),
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('adminCreateUser');

      await callable.call({
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'role': 'admin',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin account created')),
      );

      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Function error')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        title: const Text('Create Admin'),
        backgroundColor: kWhite,
        elevation: 0.8,
        foregroundColor: kDarkBlue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          /// 👤 ADMIN ICON (MATCH STYLE)
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: kSoftBlue,
              child: const Icon(
                Icons.admin_panel_settings,
                size: 36,
                color: kDarkBlue,
              ),
            ),
          ),

          const SizedBox(height: 24),

          /// 📝 FORM
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: _input('Full Name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter full name' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailController,
                  decoration: _input('Email Address'),
                  validator: (v) =>
                      v == null || !v.contains('@')
                          ? 'Enter valid email'
                          : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  decoration: _input('Password'),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 6
                          ? 'Min 6 characters'
                          : null,
                ),

                const SizedBox(height: 28),

                /// 💾 SAVE BUTTON (MATCH ADD DOCTOR)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _createAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Create Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
