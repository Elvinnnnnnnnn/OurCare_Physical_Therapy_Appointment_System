import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'doctor_chat_screen.dart';

class DoctorMessagesTab extends StatelessWidget {
  const DoctorMessagesTab({super.key});

  // 🎨 Brand colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  @override
  Widget build(BuildContext context) {
    final doctorUid = FirebaseAuth.instance.currentUser?.uid;

    if (doctorUid == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: kDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kDarkBlue),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('doctorId', isEqualTo: doctorUid)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data =
                  chats[index].data() as Map<String, dynamic>;

              final customerId = data['customerId'];

              return _CustomerChatCard(
                chatId: chats[index].id,
                customerId: customerId,
              );
            },
          );
        },
      ),
    );
  }
}

/// ===============================
/// CUSTOMER CHAT CARD (CORRECT)
/// ===============================
class _CustomerChatCard extends StatelessWidget {
  final String chatId;
  final String customerId;

  const _CustomerChatCard({
    required this.chatId,
    required this.customerId,
  });

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get(),
      builder: (context, snapshot) {
        String name = 'Patient';
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data =
              snapshot.data!.data() as Map<String, dynamic>;
          name = data['fullName'] ??
              data['name'] ??
              data['email'] ??
              'Patient';
          photoUrl = data['photoUrl'];
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorChatScreen(
                    chatId: chatId,
                    patientId: customerId,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  /// 👤 CUSTOMER PHOTO
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        kPrimaryBlue.withOpacity(0.1),
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl!) : null,
                    child: photoUrl == null
                        ? Text(
                            name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: kPrimaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 14),

                  /// NAME
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kDarkBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap to open conversation',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
