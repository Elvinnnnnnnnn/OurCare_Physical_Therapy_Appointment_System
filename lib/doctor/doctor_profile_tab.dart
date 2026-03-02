import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class DoctorProfileTab extends StatefulWidget {
  const DoctorProfileTab({super.key});

  @override
  State<DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<DoctorProfileTab> {
  // 🎨 SAME COLORS AS CUSTOMER
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kGreyText = Color(0xFF6B7280);

  final ImagePicker _picker = ImagePicker();

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  /// ======================
  /// IMAGE PICK & UPLOAD
  /// ======================
  Future<void> _changePhoto(
    String doctorId,
    String email,
  ) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked == null) return;

    final file = File(picked.path);

    final ref = FirebaseStorage.instance
        .ref()
        .child('doctors')
        .child('$doctorId.jpg');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .update({'photoUrl': url});
  }

  /// ======================
  /// EDIT FIELD DIALOG
  /// ======================
  Future<void> _editField({
    required String title,
    required String initialValue,
    required String field,
    required String doctorId,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initialValue);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
            final newValue = controller.text.trim();

            // Update doctors collection
            await FirebaseFirestore.instance
                .collection('doctors')
                .doc(doctorId)
                .update({field: newValue});

            // If editing name, also update users collection
            if (field == 'name') {
              final currentUser = FirebaseAuth.instance.currentUser;

              if (currentUser != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .update({
                  'fullName': newValue,
                });
              }
            }

            if (mounted) Navigator.pop(context);
            setState(() {});
          },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// ======================
  /// CHANGE PASSWORD
  /// ======================
  Future<void> _changePassword() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'New password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.currentUser!
                  .updatePassword(controller.text.trim());
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: kDarkBlue,
        ),
      ),
    );
  }

  Widget _profileItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kSoftBlue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimaryBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: kGreyText),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kDarkBlue,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: const Text('Change'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('doctors')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = snapshot.data!.docs.first;
        final doctor = doc.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: kWhite,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                /// HEADER
                GestureDetector(
                  onTap: () => _changePhoto(doc.id, doctor['email']),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: kPrimaryBlue,
                          backgroundImage: doctor['photoUrl'] != null
                              ? NetworkImage(doctor['photoUrl'])
                              : null,
                          child: doctor['photoUrl'] == null
                              ? Text(
                                  doctor['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: kWhite,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor['name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kDarkBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doctor['email'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kGreyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _sectionTitle('Account Information'),

                _profileItem(
                  icon: Icons.person,
                  title: 'Full Name',
                  value: doctor['name'],
                  onTap: () => _editField(
                    title: 'Edit Name',
                    initialValue: doctor['name'],
                    field: 'name',
                    doctorId: doc.id,
                  ),
                ),

                _profileItem(
                  icon: Icons.email,
                  title: 'Email Address',
                  value: doctor['email'],
                ),

                _sectionTitle('Security'),

                _profileItem(
                  icon: Icons.lock,
                  title: 'Password',
                  value: '••••••••',
                  onTap: _changePassword,
                ),

                _sectionTitle('About Me'),

                _profileItem(
                  icon: Icons.info_outline,
                  title: 'Description',
                  value: doctor['aboutMe'] ?? '',
                  onTap: () => _editField(
                    title: 'Edit About Me',
                    initialValue: doctor['aboutMe'] ?? '',
                    field: 'aboutMe',
                    doctorId: doc.id,
                    maxLines: 4,
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkBlue,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
