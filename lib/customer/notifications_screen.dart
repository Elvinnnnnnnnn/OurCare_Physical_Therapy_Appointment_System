import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    final date = (timestamp as Timestamp).toDate();

    int hour = date.hour;
    final int minute = date.minute;

    final period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final minuteStr = minute.toString().padLeft(2, '0');

    return "${date.month}/${date.day}/${date.year} $hour:$minuteStr $period";
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final unread = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      doc.reference.update({'read': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkBlue),
        title: const Text(
          'Notifications',
          style: TextStyle(color: kDarkBlue),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final notif =
                  docs[index].data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: notif['read'] == true
                      ? Colors.grey.shade100
                      : kPrimaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: notif['read'] == true
                        ? Colors.grey.shade300
                        : kPrimaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// ICON
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimaryBlue.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: kPrimaryBlue,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// TEXT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            notif['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kDarkBlue,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            notif['body'] ?? '',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            _formatDate(notif['createdAt']),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
                          },
          );
        },
      ),
    );
  }
}
