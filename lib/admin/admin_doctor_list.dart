import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_edit_doctor.dart';

class AdminDoctorList extends StatelessWidget {
  const AdminDoctorList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Doctors'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doctors = snapshot.data!.docs;

          if (doctors.isEmpty) {
            return const Center(child: Text('No doctors found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              final data = doctor.data() as Map<String, dynamic>;

              return _DoctorTile(
                doctorId: doctor.id,
                doctorData: data,
              );
            },
          );
        },
      ),
    );
  }
}

/// ======================
/// DOCTOR TILE
/// ======================
class _DoctorTile extends StatelessWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const _DoctorTile({
    required this.doctorId,
    required this.doctorData,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = doctorData['available'] == true;
    final isActivated = doctorData['activated'] ?? false;
    final String? photoUrl = doctorData['photoUrl'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 👨‍⚕️ Doctor info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🖼️ DOCTOR PHOTO (UPDATED)
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person,
                          color: Colors.grey,
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                /// Doctor details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorData['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        doctorData['categoryName'] ?? 'No category',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctorData['email'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActivated ? 'Activated' : 'Not Activated',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActivated ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🗑 DELETE
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _confirmDelete(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// ⭐ Rating
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  ((doctorData['averageRating'] ?? 0).toDouble())
                      .toStringAsFixed(1),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${doctorData['totalRatings'] ?? 0})',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// ⚙️ ACTION BUTTONS
            Row(
              children: [
                /// EDIT
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () {
                    _openEditDoctor(context);
                  },
                ),

                /// ENABLE / DISABLE
                TextButton.icon(
                  icon: Icon(
                    isAvailable ? Icons.visibility_off : Icons.visibility,
                    color: isAvailable ? Colors.orange : Colors.green,
                  ),
                  label: Text(isAvailable ? 'Disable' : 'Enable'),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('doctors')
                        .doc(doctorId)
                        .update({'available': !isAvailable});
                  },
                ),

                /// ACTIVATE
                TextButton.icon(
                  icon: Icon(
                    Icons.verified,
                    color: isActivated ? Colors.green : Colors.red,
                  ),
                  label: Text(isActivated ? 'Activated' : 'Activate'),
                  onPressed: isActivated
                      ? null
                      : () async {
                          await FirebaseFirestore.instance
                              .collection('doctors')
                              .doc(doctorId)
                              .update({'activated': true});
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ======================
  /// DELETE CONFIRMATION
  /// ======================
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: const Text(
          'This will remove the doctor from Firestore.\n\nThe login account will NOT be deleted.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('doctors')
                  .doc(doctorId)
                  .delete();

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// ======================
  /// EDIT DOCTOR
  /// ======================
  void _openEditDoctor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditDoctorScreen(
          doctorId: doctorId,
          doctorData: doctorData,
        ),
      ),
    );
  }
}
