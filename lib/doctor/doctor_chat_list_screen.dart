import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 👉 change this import to your actual chat screen
// import 'chat_room_screen.dart';

class DoctorChatListScreen extends StatelessWidget {
  const DoctorChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // ⏳ Auth loading
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔒 Logged out
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const Center(
            child: Text('Please log in'),
          );
        }

        final doctorAuthUid = authSnapshot.data!.uid;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('doctorId', isEqualTo: doctorAuthUid)
              .orderBy('updatedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No messages yet'),
              );
            }

            final chats = snapshot.data!.docs;

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final doc = chats[index];
                final data = doc.data() as Map<String, dynamic>?;

                if (data == null) return const SizedBox();

                final customerName =
                    data['customerName']?.toString() ?? 'Patient';
                final lastMessage =
                    data['lastMessage']?.toString() ?? '';

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(customerName),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // 🔜 Open chat screen here
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (_) => ChatRoomScreen(
                    //       chatId: doc.id,
                    //       doctorId: doctorAuthUid,
                    //       customerId: data['customerId'],
                    //     ),
                    //   ),
                    // );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
