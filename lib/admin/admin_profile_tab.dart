import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  // 🎨 Brand colors
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

  /// 🔹 LOAD FULL NAME
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

  /// ✏️ UPDATE FULL NAME
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

  /// 🔒 CHANGE PASSWORD
  Future<void> _changePassword() async {
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _loadingPassword = true);

    try {
      await user!.updatePassword(_passwordController.text.trim());
      _passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Password update failed')),
      );
    }

    setState(() => _loadingPassword = false);
  }

  /// 🚪 LOGOUT
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// 👤 AVATAR
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: kSoftBlue,
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 40,
                        color: kDarkBlue,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// ROLE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kDarkBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// EMAIL
                    _infoTile(
                      icon: Icons.email,
                      label: 'Email',
                      value: user?.email ?? 'Unknown',
                    ),

                    const SizedBox(height: 20),

                    /// ✏️ FULL NAME
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadingName ? null : _updateName,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                        ),
                        child: _loadingName
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Name'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// 🔒 CHANGE PASSWORD
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _loadingPassword ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                        ),
                        child: _loadingPassword
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Change Password'),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// 🚪 LOGOUT
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: _logout,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
