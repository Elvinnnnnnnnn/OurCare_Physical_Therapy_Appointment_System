import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorChatScreen extends StatefulWidget {
  final String chatId;
  final String patientId;

  const DoctorChatScreen({
    super.key,
    required this.chatId,
    required this.patientId,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  // 🎨 BRAND COLORS
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  String patientName = 'Patient';
  String? patientPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  /// 👤 LOAD PATIENT NAME + PHOTO
  Future<void> _loadPatientProfile() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .get();

    if (snap.exists && mounted) {
      final data = snap.data()!;
      setState(() {
        patientName =
            data['fullName'] ??
            data['name'] ??
            data['email'] ??
            'Patient';

        patientPhotoUrl = data['photoUrl'];
      });
    }
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': user!.uid,
      'text': _controller.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': _controller.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,

      /// 🧑‍⚕️ APP BAR (PATIENT PHOTO + NAME)
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkBlue),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kPrimaryBlue.withOpacity(0.1),
              backgroundImage: patientPhotoUrl != null
                  ? NetworkImage(patientPhotoUrl!)
                  : null,
              child: patientPhotoUrl == null
                  ? Text(
                      patientName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: kPrimaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                patientName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kDarkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),

      /// 💬 BODY
      body: Column(
        children: [
          /// MESSAGES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == user!.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? kPrimaryBlue : kSoftBlue,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft:
                                Radius.circular(isMe ? 18 : 4),
                            bottomRight:
                                Radius.circular(isMe ? 4 : 18),
                          ),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? kWhite : kDarkBlue,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ✍️ INPUT BAR
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: kWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: kPrimaryBlue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: kWhite),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
