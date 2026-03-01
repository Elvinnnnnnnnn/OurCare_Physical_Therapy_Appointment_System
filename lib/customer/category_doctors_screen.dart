import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_details_screen.dart';

class CategoryDoctorsScreen extends StatelessWidget {
  final String categoryName;
  final String description;
  final String? imageUrl;

  const CategoryDoctorsScreen({
    super.key,
    required this.categoryName,
    required this.description,
    required this.imageUrl,
  });

  // Brand colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kGreyText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,

      /// APP BAR
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkBlue),
        title: Text(
          categoryName,
          style: const TextStyle(
            color: kDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      /// BODY
      body: Column(
        children: [
          /// 🧩 CATEGORY HEADER
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSoftBlue.withOpacity(0.4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: kSoftBlue,
                  backgroundImage:
                      imageUrl != null ? NetworkImage(imageUrl!) : null,
                  child: imageUrl == null
                      ? const Icon(Icons.medical_services,
                          color: kPrimaryBlue)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kDarkBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description.isNotEmpty
                            ? description
                            : 'No description provided.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: kGreyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// 👨‍⚕️ DOCTORS LIST
          Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('doctors')
        .where('categoryName', isEqualTo: categoryName)
        .where('activated', isEqualTo: true) // use this instead of 'available'
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final doctors = snapshot.data!.docs;

      if (doctors.isEmpty) {
        return const Center(
          child: Text(
            'No doctors in this service',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          final data = doctor.data() as Map<String, dynamic>;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorDetailsScreen(
                    doctorId: doctor.id,
                    doctorData: data,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: data['photoUrl'] != null
                        ? NetworkImage(data['photoUrl'])
                        : null,
                    child: data['photoUrl'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      data['name'] ?? 'Unknown Doctor',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
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
)
        ],
      ),
    );
  }
}
