import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// 🎨 BRAND COLORS (GLOBAL)
const Color kWhite = Color(0xFFFFFFFF);
const Color kPrimaryBlue = Color(0xFF1562E2);
const Color kDarkBlue = Color(0xFF001C99);
const Color kSoftBlue = Color(0xFFB3EBF2);

class AdminUserList extends StatelessWidget {
  final String role;

  const AdminUserList({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkBlue),
        title: Text(
          '${role[0].toUpperCase()}${role.substring(1)} Accounts',
          style: const TextStyle(
            color: kDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: role)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final users = snapshot.data!.docs;

            if (users.isEmpty) {
              return Center(
                child: Text('No $role accounts'),
              );
            }

            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = users[index];
                final data = doc.data() as Map<String, dynamic>;

                return _UserCard(
                  userId: doc.id,
                  role: role,
                  data: data,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// ======================
/// USER CARD (ALL ROLES)
/// ======================
class _UserCard extends StatelessWidget {
  final String userId;
  final String role;
  final Map<String, dynamic> data;

  const _UserCard({
    required this.userId,
    required this.role,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isSelf = userId == currentUserId;

    final String fullName = data['fullName'] ?? 'No name';
    final String email = data['email'] ?? '';
    final bool isDisabled = data['disabled'] == true;
    final String? userPhotoUrl = data['photoUrl']; // customers/admins

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          /// 👤 PROFILE PHOTO (ALL ROLES)
          _buildAvatar(fullName, userPhotoUrl),

          const SizedBox(width: 14),

          /// USER INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    _badge(role.toUpperCase(), kPrimaryBlue),
                    const SizedBox(width: 6),
                    _badge(
                      isDisabled ? 'DISABLED' : 'ACTIVE',
                      isDisabled ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// MENU
          PopupMenuButton<String>(
            onSelected: isSelf
                ? null
                : (value) {
                    if (value == 'toggle') {
                      _toggleStatus(userId, isDisabled);
                    }
                    if (value == 'delete') {
                      _confirmDelete(context, userId, role);
                    }
                  },
            itemBuilder: (context) => isSelf
                ? const []
                : const [
                    PopupMenuItem(value: 'toggle', child: Text('Enable / Disable')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  /// 🔥 AVATAR LOGIC (THIS IS THE FIX)
  Widget _buildAvatar(String fullName, String? userPhotoUrl) {
    // ✅ CUSTOMER / ADMIN (photo in users)
    if (role != 'doctor') {
      return CircleAvatar(
        radius: 26,
        backgroundColor: kSoftBlue,
        backgroundImage:
            userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
        child: userPhotoUrl == null
            ? Text(
                fullName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: kDarkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
      );
    }

    // 👨‍⚕️ DOCTOR (photo from doctors collection)
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('doctors')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        String? doctorPhoto;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          doctorPhoto = snapshot.data!.docs.first['photoUrl'];
        }

        return CircleAvatar(
          radius: 26,
          backgroundColor: kSoftBlue,
          backgroundImage:
              doctorPhoto != null ? NetworkImage(doctorPhoto) : null,
          child: doctorPhoto == null
              ? Text(
                  fullName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: kDarkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _toggleStatus(String userId, bool disabled) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'disabled': !disabled});
  }

  void _confirmDelete(BuildContext context, String userId, String role) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'This will remove the $role profile.\n\nLogin account will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFunctions.instanceFor(region: 'us-central1')
                .httpsCallable('adminDeleteUser')
                .call({'uid': userId});
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
