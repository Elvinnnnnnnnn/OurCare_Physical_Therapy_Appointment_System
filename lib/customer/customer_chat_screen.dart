import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../shared/video_call_screen.dart';
import '../shared/incoming_call_screen.dart';

class CustomerChatScreen extends StatefulWidget {
  final String chatId;
  final String doctorName;

  const CustomerChatScreen({
    super.key,
    required this.chatId,
    required this.doctorName,
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  // 🎨 Brand colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  final ScrollController _scrollController = ScrollController();
  bool isIncomingScreenOpen = false;

  String doctorName = 'Doctor';
  String? doctorPhotoUrl;

  String? lastCallId;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  /// 👨‍⚕️ LOAD DOCTOR NAME + PHOTO
  Future<void> _loadDoctorProfile() async {
    final chatSnap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();

    if (!chatSnap.exists) return;

    final doctorAuthUid = chatSnap['doctorId'];

    final doctorSnap = await FirebaseFirestore.instance
        .collection('doctors')
        .where('userId', isEqualTo: doctorAuthUid) // ✅ CORRECT
        .limit(1)
        .get();

    if (doctorSnap.docs.isNotEmpty && mounted) {
      final data =
          doctorSnap.docs.first.data() as Map<String, dynamic>;
      setState(() {
        doctorName = data['name'] ?? 'Doctor';
        doctorPhotoUrl = data['photoUrl'];
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

      /// 👨‍⚕️ APP BAR — DOCTOR PHOTO + NAME
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkBlue),

        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: kPrimaryBlue.withOpacity(0.1),
              backgroundImage: doctorPhotoUrl != null
                  ? NetworkImage(doctorPhotoUrl!)
                  : null,
              child: doctorPhotoUrl == null
                  ? Text(
                      doctorName.substring(0, 1).toUpperCase(),
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
                doctorName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kDarkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.video_call, color: kPrimaryBlue),
            onPressed: () async {
              final existingCall = await FirebaseFirestore.instance
                .collection('calls')
                .where('chatId', isEqualTo: widget.chatId)
                .where('status', isEqualTo: 'calling')
                .get();

              if (existingCall.docs.isNotEmpty) {
                print("CALL ALREADY EXISTS");
                return;
              }

              final chatSnap = await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .get();

              final doctorAuthUid = chatSnap['doctorId'];

              final callId = FirebaseFirestore.instance.collection('calls').doc().id;
              final channelName = DateTime.now().millisecondsSinceEpoch.toString();

              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get();

              final userData = userDoc.data();

              await FirebaseFirestore.instance.collection('calls').doc(callId).set({
                'callerId': user!.uid,
                'receiverId': doctorAuthUid,
                'channelName': channelName,
                'chatId': widget.chatId,

                // 🔥 FIXED
                'callerName': userData?['fullName'] ?? 'Patient',
                'callerPhoto': userData?['photoUrl'],

                'receiverName': doctorName,
                'receiverPhoto': doctorPhotoUrl,

                'status': 'calling',
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoCallScreen(
                    channelName: channelName,
                    callId: callId,
                    chatId: widget.chatId,
                    isCaller: true,
                  ),
                ),
              );
            }
          ),
        ],
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
                      child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final data = msg.data() as Map<String, dynamic>;

                    final isMe = data['senderId'] == user!.uid;

                    if (data.containsKey('type') && data['type'] == 'call') {
                      final Timestamp? ts = data['createdAt'];

                      String time = '';

                      if (ts != null) {
                        final dt = ts.toDate();
                        time = DateFormat('hh:mm a').format(dt);
                      }

                      return Center(
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                data['text'] ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              time,
                              style: TextStyle(
                                color: Colors.grey.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final Timestamp? ts = data['createdAt'];

                    String time = '';

                    if (ts != null) {
                      final dt = ts.toDate();
                      time = DateFormat('hh:mm a').format(dt); // 12-hour format
                    }

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints:
                            const BoxConstraints(maxWidth: 280),
                        margin:
                            const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? kPrimaryBlue
                              : kSoftBlue,
                          borderRadius: BorderRadius.only(
                            topLeft:
                                const Radius.circular(18),
                            topRight:
                                const Radius.circular(18),
                            bottomLeft: Radius.circular(
                                isMe ? 18 : 4),
                            bottomRight: Radius.circular(
                                isMe ? 4 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              data['text'],
                              style: TextStyle(
                                color: isMe ? kWhite : kDarkBlue,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                color: isMe
                                    ? kWhite.withOpacity(0.7)
                                    : kDarkBlue.withOpacity(0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
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
                  horizontal: 12, vertical: 8),
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
                        fillColor:
                            Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: kPrimaryBlue,
                    child: IconButton(
                      icon: const Icon(Icons.send,
                          color: kWhite),
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
