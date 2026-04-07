import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_details_screen.dart';
import 'category_doctors_screen.dart';
import 'notifications_screen.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CustomerHomeTab extends StatefulWidget {
  const CustomerHomeTab({super.key});

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  // Brand colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  late StreamSubscription _appointmentListener;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  
  Future<void> _saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'fcmToken': token,
    });

    print("FCM TOKEN SAVED: $token");
  }

 @override
  void initState() {
    super.initState();

    _saveFcmToken();
    _checkExistingApprovedAppointments();
    _listenForApprovedAppointments();

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': newToken,
        });
      }
    });
  }

  void _listenForApprovedAppointments() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _appointmentListener = FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((snapshot) async {
      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (data['reminderScheduled'] == true) {
          print("Already scheduled, skipping");
          continue;
        }

        if (data['appointmentAt'] == null) continue;
        final Timestamp ts = data['appointmentAt'];
        final DateTime appointmentDateTime = ts.toDate();

        if (appointmentDateTime.difference(DateTime.now()).inMinutes < 1) {
        print("Too late to schedule");
        continue;
}

        if (appointmentDateTime.isBefore(DateTime.now())) continue;

        print("FOUND APPROVED APPOINTMENT");

        await NotificationService.requestPermissions();

        await NotificationService.scheduleAllReminders(
          appointmentDateTime: appointmentDateTime,
        );

        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(doc.id)
            .update({
          'reminderScheduled': true,
        });

        print("Reminders scheduled on patient device");
      }
    });
  }

  Future<void> _checkExistingApprovedAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'approved')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['reminderScheduled'] == true) {
        print("Already scheduled, skipping");
        continue;
      }

      if (data['appointmentAt'] == null) continue;
      final Timestamp ts = data['appointmentAt'];
      final DateTime appointmentDateTime = ts.toDate();

      if (appointmentDateTime.difference(DateTime.now()).inMinutes < 1) {
      print("Too late to schedule");
      continue;
}

      if (appointmentDateTime.isBefore(DateTime.now())) continue;

      print("FOUND EXISTING APPROVED APPOINTMENT");

      await NotificationService.requestPermissions();

      await NotificationService.scheduleAllReminders(
        appointmentDateTime: appointmentDateTime,
      );

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(doc.id)
          .update({
        'reminderScheduled': true,
      });

      print("Reminders scheduled from existing data");
      
    }
  }

  @override
  void dispose() {
    _appointmentListener.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔍 SEARCH
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchText = value.trim().toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search therapist or services',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              /// 🔔 NOTIFICATIONS (WITH RED BADGE)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .where('read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final hasUnread =
                      snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                  return Align(
                    alignment: Alignment.centerRight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: kPrimaryBlue,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                        ),

                        /// 🔴 RED DOT
                        if (hasUnread)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              /// 🧩 SERVICES
              const Text(
                'Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kDarkBlue,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 96,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final allCategories = snapshot.data!.docs;

                    final categories = allCategories.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final name =
                          (data['name'] ?? '').toString().toLowerCase();

                      return _searchText.isEmpty || name.contains(_searchText);
                    }).toList();

                    if (categories.isEmpty) {
                      return const Center(
                        child: Text('No matching services'),
                      );
                    }

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final data =
                            category.data() as Map<String, dynamic>;

                        return _CategoryItem(
                          name: data['name'],
                          imageUrl: data['imageUrl'],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryDoctorsScreen(
                                  categoryId: category.id,
                                  categoryName: data['name'],
                                  description: data['description'] ?? '',
                                  imageUrl: data['imageUrl'],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              /// 👨‍⚕️ DOCTORS
              const Text(
                'Top Specialists',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kDarkBlue,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('doctors')
                      .where('activated', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final allDoctors = snapshot.data!.docs;

                    final filteredDoctors = allDoctors.where((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;

                      final name =
                          (data['name'] ?? '')
                              .toString()
                              .toLowerCase();
                      final category =
                          (data['categoryName'] ?? '')
                              .toString()
                              .toLowerCase();

                      return _searchText.isEmpty ||
                          name.contains(_searchText) ||
                          category.contains(_searchText);
                    }).toList();

                    if (filteredDoctors.isEmpty) {
                      return const Center(
                        child: Text(
                          'No doctors found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding:
                          const EdgeInsets.only(bottom: 16),
                      itemCount: filteredDoctors.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        return _DoctorCard(
                          doctor: filteredDoctors[index],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// SERVICE ITEM
/// ===============================
class _CategoryItem extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: kSoftBlue,
              borderRadius: BorderRadius.circular(16),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? const Icon(
                    Icons.medical_services,
                    color: kPrimaryBlue,
                    size: 26,
                  )
                : null,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// DOCTOR CARD
/// ===============================
class _DoctorCard extends StatelessWidget {
  final QueryDocumentSnapshot doctor;

  const _DoctorCard({required this.doctor});

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  String _getInitial(String name) {
    if (name.trim().isEmpty) return 'D';
    return name.trim()[0].toUpperCase();
  }

  bool isAvailableToday(Map<String, dynamic> data) {
    if (data['availability'] == null) return false;

    final availability = Map<String, dynamic>.from(data['availability']);

    final today = DateFormat('EEEE').format(DateTime.now()).toLowerCase();

    if (!availability.containsKey(today)) return false;

    final dayData = availability[today];

    if (dayData is Map) {
      return dayData['enabled'] == true;
    }

    if (dayData is List) {
      return dayData.isNotEmpty;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final data = doctor.data() as Map<String, dynamic>;
    final bool availableToday = isAvailableToday(data);

    final double averageRating =
      (data['averageRating'] ?? 0).toDouble();
    final int totalRatings =
      (data['totalRatings'] ?? 0) as int;

    final int price = (data['consultationPrice'] ?? 0).toInt();
    final String currency = data['currency'] ?? 'PHP';
    final formattedPrice = NumberFormat('#,###').format(price);

    final String? photoUrl = data['photoUrl'];

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
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      _getInitial(data['name'] ?? ''),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: kDarkBlue,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
           Flexible(
              child: Text(
                data['name'] ?? 'Unknown Doctor',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kDarkBlue,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('categories')
                  .where(
                    FieldPath.documentId,
                    whereIn: List<String>.from(data['categoryIds'] ?? []),
                  )
                  .get(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const SizedBox(height: 14);
                }

                final names = snapshot.data!.docs
                    .map((e) => e['name'])
                    .join(', ');

                return Flexible(
                  child: Text(
                    names,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              '₱$formattedPrice',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue,
                fontSize: 15,
              ),
            ),

           const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: availableToday
                      ? Colors.green.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  availableToday ? 'Available Today' : 'Not Available Today',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: availableToday ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
