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
          /// 🧩 SERVICE HEADER (NEW – SAFE)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSoftBlue.withOpacity(0.4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// IMAGE
                CircleAvatar(
                  radius: 30,
                  backgroundColor: kSoftBlue,
                  backgroundImage:
                      imageUrl != null ? NetworkImage(imageUrl!) : null,
                  child: imageUrl == null
                      ? const Icon(
                          Icons.medical_services,
                          color: kPrimaryBlue,
                          size: 26,
                        )
                      : null,
                ),

                const SizedBox(width: 14),

                /// TEXT
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

          /// 👨‍⚕️ DOCTORS LIST (UNCHANGED)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doctors')
                  .where('categoryName', isEqualTo: categoryName)
                  .where('available', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
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
                    final data =
                        doctor.data() as Map<String, dynamic>;

                    final double avgRating =
                        (data['averageRating'] ?? 0).toDouble();
                    final int totalRatings =
                        (data['totalRatings'] ?? 0) as int;

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
                          color: kWhite,
                          borderRadius:
                              BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            /// AVATAR
                            const CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  AssetImage('assets/placeholder-400x400.jpg'),
                            ),

                            const SizedBox(width: 14),

                            /// INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ??
                                        'Unknown Doctor',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                      color: kDarkBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['categoryName'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// ⭐ RATING
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange
                                    .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '($totalRatings)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 6),

                            /// ARROW
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
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
        ],
      ),
    );
  }
}
