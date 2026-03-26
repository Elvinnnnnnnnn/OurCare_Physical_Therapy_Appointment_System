import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              '${role[0].toUpperCase()}${role.substring(1)} Accounts',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
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
                      final data =
                          doc.data() as Map<String, dynamic>;

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
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String userId;
  final String role;
  final Map<String, dynamic> data;

  const _UserCard({
    required this.userId,
    required this.role,
    required this.data,
  });

  String _getInitial(String name) {
    if (name.trim().isEmpty) return 'D';
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isSelf = userId == currentUserId;

    final String fullName = data['fullName'] ?? 'No name';
    final String email = data['email'] ?? '';
    final bool isDisabled = data['disabled'] == true;
    final String? userPhotoUrl = data['photoUrl'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [

          CircleAvatar(
            radius: 26,
            backgroundColor: kSoftBlue,
            backgroundImage:
                userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
            child: userPhotoUrl == null
                ? Text(
                    _getInitial(fullName),
                    style: const TextStyle(
                      color: kDarkBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName),
                Text(email,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          Row(
            children: [

              Text(
                isDisabled ? 'DISABLED' : 'ACTIVE',
                style: TextStyle(
                  color: isDisabled ? Colors.red : Colors.green,
                ),
              ),

              const SizedBox(width: 10),

              if (!isSelf)
                IconButton(
                  icon: const Icon(Icons.block),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update({
                      'disabled': !isDisabled
                    });
                  },
                ),

              if (!isSelf)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .delete();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}