import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminDoctorList extends StatelessWidget {
  final Function(String, Map<String, dynamic>) onEdit;

  const AdminDoctorList({
    super.key,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final doctors = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: doctors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = doctors[index];
            final data = doc.data() as Map<String, dynamic>;
            final String? photoUrl = data['photoUrl'];

            final isAvailable = data['available'] == true;
            final isActivated = data['activated'] ?? false;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [

                  // IMAGE
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF1562E2).withOpacity(0.1),
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            (data['name'] != null && data['name'].toString().isNotEmpty)
                                ? data['name'].toString()[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1562E2),
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // NAME + EMAIL
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['email'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STATUS
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActivated
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActivated ? 'Activated' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActivated
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // ACTIONS
                  Row(
                    children: [

                      _actionBtn(
                        icon: Icons.edit,
                        color: Colors.blue,
                        onTap: () {
                          onEdit(doc.id, data);
                        },
                      ),

                      const SizedBox(width: 6),

                      _actionBtn(
                        icon: isAvailable
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('doctors')
                              .doc(doc.id)
                              .update({
                            'available': !isAvailable
                          });
                        },
                      ),

                      const SizedBox(width: 6),

                      _actionBtn(
                        icon: Icons.delete,
                        color: Colors.red,
                        onTap: () {
                          _confirmDelete(context, doc.id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String doctorId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {

                final callable = FirebaseFunctions.instanceFor(
                  region: 'us-central1',
                ).httpsCallable('adminDeleteDoctor');

                await callable.call({
                  'uid': doctorId,
                });

                Navigator.pop(context);

              } catch (e) {
                print(e);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete failed')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}