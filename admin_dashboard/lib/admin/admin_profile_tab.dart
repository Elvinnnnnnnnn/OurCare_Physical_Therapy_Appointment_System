import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loadingName = false;
  bool _loadingPassword = false;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (snap.exists) {
      _nameController.text = snap['fullName'] ?? '';
    }
  }

  Future<void> _updateName() async {

    if (_nameController.text.trim().isEmpty) return;

    setState(() => _loadingName = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({
      'fullName': _nameController.text.trim(),
    });

    setState(() => _loadingName = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full name updated')),
    );
  }

  Future<void> _changePassword() async {

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password too short')),
      );
      return;
    }

    setState(() => _loadingPassword = true);

    try {
      await user!.updatePassword(_passwordController.text.trim());
      _passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => _loadingPassword = false);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [

              /// PROFILE HEADER
              Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: kSoftBlue,
                    child: const Icon(Icons.admin_panel_settings),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kDarkBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// ACCOUNT
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Account Info',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kDarkBlue,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(user?.email ?? ''),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _nameController,
                      decoration: _input('Full Name'),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed:
                            _loadingName ? null : _updateName,
                        child: _loadingName
                            ? const CircularProgressIndicator()
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),

              /// PASSWORD
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kDarkBlue,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _input('New Password'),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _loadingPassword
                            ? null
                            : _changePassword,
                        child: _loadingPassword
                            ? const CircularProgressIndicator()
                            : const Text('Update Password'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// LOGOUT
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: _logout,
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}