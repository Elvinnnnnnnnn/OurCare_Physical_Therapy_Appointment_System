import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'customer_chat_screen.dart';

class CustomerMessagesTab extends StatelessWidget {
  const CustomerMessagesTab({super.key});

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
            .where('customerId', isEqualTo: user!.uid)
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chat = snapshot.data!.docs[index];
              final data = chat.data() as Map<String, dynamic>;

              return _DoctorChatCard(
                chatId: chat.id,
                doctorAuthUid: data['doctorId'], // 🔑 AUTH UID
              );
            },
          );
        },
      ),
    );
  }
}

/// ===============================
/// DOCTOR CHAT CARD (FIXED)
/// ===============================
class _DoctorChatCard extends StatelessWidget {
  final String chatId;
  final String doctorAuthUid;

  const _DoctorChatCard({
    required this.chatId,
    required this.doctorAuthUid,
  });

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('doctors')
          .where('userId', isEqualTo: doctorAuthUid) // ✅ FIX
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        String doctorName = 'Doctor';
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;
          doctorName = data['name'] ?? 'Doctor';
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
                  builder: (_) => CustomerChatScreen(
                    chatId: chatId,
                    doctorName: doctorName,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  /// 👨‍⚕️ DOCTOR PHOTO
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        kPrimaryBlue.withOpacity(0.1),
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            doctorName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: kPrimaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
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
