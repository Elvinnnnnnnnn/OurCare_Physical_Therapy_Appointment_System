import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDoctorsTab extends StatelessWidget {
  const AdminDoctorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No doctors found'));
        }

        final doctors = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doc = doctors[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(data['name'] ?? 'No name'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['categoryName'] ?? ''),
                    Text('Experience: ${data['experience'] ?? ''}'),
                    Text(
                      'Status: ${data['available'] == true ? 'Active' : 'Disabled'}',
                      style: TextStyle(
                        color: data['available'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'disable') {
                      FirebaseFirestore.instance
                          .collection('doctors')
                          .doc(doc.id)
                          .update({'available': false});
                    }
                    if (value == 'enable') {
                      FirebaseFirestore.instance
                          .collection('doctors')
                          .doc(doc.id)
                          .update({'available': true});
                    }
                    if (value == 'delete') {
                      FirebaseFirestore.instance
                          .collection('doctors')
                          .doc(doc.id)
                          .delete();
                    }
                  },
                  itemBuilder: (context) => [
                    if (data['available'] == true)
                      const PopupMenuItem(
                        value: 'disable',
                        child: Text('Disable'),
                      )
                    else
                      const PopupMenuItem(
                        value: 'enable',
                        child: Text('Enable'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
