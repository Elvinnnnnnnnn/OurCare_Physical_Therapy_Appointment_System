import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color kDarkBlue = Color(0xFF001C99);

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    final date = (timestamp as Timestamp).toDate();

    int hour = date.hour;
    final int minute = date.minute;

    final String period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final String minuteStr = minute.toString().padLeft(2, '0');

    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
          "$hour:$minuteStr $period";
  }

  @override
  Widget build(BuildContext context) {

    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: data['read'] == true
                      ? Colors.grey.shade100
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: data['read'] == true
                        ? Colors.grey.shade300
                        : Colors.blue.shade200,
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(doc.id)
                        .update({'read': true});
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              data['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: kDarkBlue,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              data['body'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              _formatDate(data['createdAt']),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}