import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_edit_doctor.dart';

class AdminDoctorList extends StatelessWidget {
  const AdminDoctorList({super.key});

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,

      appBar: AppBar(
        title: const Text(
          'Doctors',
          style: TextStyle(
            color: kDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kWhite,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: kDarkBlue),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: kPrimaryBlue,
              ),
            );
          }

          final doctors = snapshot.data!.docs;

          if (doctors.isEmpty) {
            return const Center(
              child: Text(
                'No doctors found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
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

class _DoctorTile extends StatelessWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const _DoctorTile({
    required this.doctorId,
    required this.doctorData,
  });

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  String _getInitial(String name) {
    if (name.trim().isEmpty) return 'D';
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = doctorData['available'] == true;
    final isActivated = doctorData['activated'] ?? false;
    final String? photoUrl = doctorData['photoUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: kSoftBlue,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        _getInitial(doctorData['name'] ?? ''),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: kDarkBlue,
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
                      doctorData['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: kDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('categories')
                          .where(
                            FieldPath.documentId,
                            whereIn: (doctorData['categoryIds'] ?? []),
                          )
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Text(
                            'Loading...',
                            style: TextStyle(fontSize: 12),
                          );
                        }

                        final names = snapshot.data!.docs
                            .map((e) => e['name'])
                            .join(', ');

                        return Text(
                          names.isEmpty ? 'No category' : names,
                          style: const TextStyle(
                            color: kPrimaryBlue,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      doctorData['email'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActivated
                            ? Colors.green.withOpacity(.12)
                            : Colors.red.withOpacity(.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActivated ? 'Activated' : 'Not Activated',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActivated ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                onPressed: () {
                  _confirmDelete(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Text(
                ((doctorData['averageRating'] ?? 0).toDouble())
                    .toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${doctorData['totalRatings'] ?? 0})',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _actionButton(
                icon: Icons.edit,
                label: 'Edit',
                color: kPrimaryBlue,
                onTap: () {
                  _openEditDoctor(context);
                },
              ),
              const SizedBox(width: 10),
              _actionButton(
                icon: isAvailable ? Icons.visibility_off : Icons.visibility,
                label: isAvailable ? 'Disable' : 'Enable',
                color: isAvailable ? Colors.orange : Colors.green,
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('doctors')
                      .doc(doctorId)
                      .update({'available': !isAvailable});
                },
              ),
              const SizedBox(width: 10),
              _actionButton(
                icon: Icons.verified,
                label: isActivated ? 'Activated' : 'Activate',
                color: isActivated ? Colors.green : Colors.red,
                onTap: isActivated
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
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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