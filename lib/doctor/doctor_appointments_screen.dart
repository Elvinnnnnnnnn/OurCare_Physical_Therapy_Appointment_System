import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends State<DoctorAppointmentsScreen> {
  int selectedTab = 0;

  final tabs = ['Pending', 'Approved', 'Cancelled'];

  // 🎨 BRAND COLORS
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  String? doctorFirestoreId;
  String? doctorPhotoUrl; // ✅ ADD
  bool isLoadingDoctor = true;

  String getStatusFilter() {
    if (selectedTab == 0) return 'pending';
    if (selectedTab == 1) return 'approved';
    return 'cancelled';
  }

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doctorSnap = await FirebaseFirestore.instance
        .collection('doctors')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (doctorSnap.docs.isNotEmpty) {
      final doc = doctorSnap.docs.first;
      setState(() {
        doctorFirestoreId = doc.id;
        doctorPhotoUrl = doc.data()['photoUrl']; // ✅ ADD
        isLoadingDoctor = false;
      });
    } else {
      setState(() {
        doctorFirestoreId = null;
        isLoadingDoctor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingDoctor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (doctorFirestoreId == null) {
      return const Scaffold(
        body: Center(child: Text('Doctor profile not found')),
      );
    }

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Appointments',
          style: TextStyle(
            color: kDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kDarkBlue),
      ),
      body: Column(
        children: [
          /// 🔘 TABS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: kSoftBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final selected = selectedTab == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? kPrimaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tabs[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? kWhite : kDarkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          /// 📋 APPOINTMENTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: doctorFirestoreId)
                  .where('status', isEqualTo: getStatusFilter())
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final appointments = snapshot.data!.docs;

                if (appointments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No appointments found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final data = appointments[index].data()
                        as Map<String, dynamic>;

                    return _DoctorAppointmentCard(
                      appointment: data,
                      appointmentId: appointments[index].id,
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

/// ===============================
/// APPOINTMENT CARD
/// ===============================
class _DoctorAppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String appointmentId;

  const _DoctorAppointmentCard({
    required this.appointment,
    required this.appointmentId,
  });

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  Color statusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    return Colors.orange;
  }

  String statusText(String status) {
    if (status == 'approved') return 'Approved';
    if (status == 'cancelled') return 'Cancelled';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final status = appointment['status'];
    final String patientId = appointment['userId']; // 🔑 patient UID

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            children: [
              /// ✅ PATIENT PROFILE PHOTO (FROM users COLLECTION)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(appointment['userId']) // patient uid
                    .get(),
                builder: (context, snapshot) {
                  String? photoUrl;

                  // ✅ SAFE INITIAL
                  final String name =
                      (appointment['patientName'] ?? 'U').toString();
                  final String initial =
                      name.isNotEmpty ? name[0].toUpperCase() : 'U';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    photoUrl = data?['photoUrl']; // ✅ SAFE ACCESS
                  }

                  return CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                    child: photoUrl == null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kDarkBlue,
                            ),
                          )
                        : null,
                  );
                },
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['patientName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kDarkBlue,
                      ),
                    ),
                    Text(
                      appointment['categoryName'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText(status),
                  style: TextStyle(
                    color: statusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// DATE & TIME
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: kPrimaryBlue),
              const SizedBox(width: 6),
              Text(appointment['date']),
              const SizedBox(width: 18),
              const Icon(Icons.access_time,
                  size: 16, color: kPrimaryBlue),
              const SizedBox(width: 6),
              Text(appointment['time']),
            ],
          ),

          /// ACTIONS
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateStatus('cancelled'),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        _updateStatus('approved'),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

    Future<void> _updateStatus(String newStatus) async {
      final Map<String, dynamic> updateData = {
        'status': newStatus,
      };

      if (newStatus == 'approved') {
        // 🔹 date example: "2026-2-3"
        final String dateStr = appointment['date'];

        // 🔹 time example: "7:55 PM – 9:00 PM"
        final String rawTime = appointment['time'];
        final String startTime = rawTime.split('–').first.trim(); // "7:55 PM"

        // ---- Parse DATE ----
        final parts = dateStr.split('-');
        final int year = int.parse(parts[0]);
        final int month = int.parse(parts[1]);
        final int day = int.parse(parts[2]);

        // ---- Parse TIME ----
        final timeParts = startTime.split(' ');
        final clock = timeParts[0]; // "7:55"
        final meridiem = timeParts[1]; // "PM"

        final hm = clock.split(':');
        int hour = int.parse(hm[0]);
        final int minute = int.parse(hm[1]);

        // Convert PM → 24h
        if (meridiem == 'PM' && hour != 12) hour += 12;
        if (meridiem == 'AM' && hour == 12) hour = 0;

        final DateTime appointmentDateTime = DateTime(
          year,
          month,
          day,
          hour,
          minute,
        );

        updateData.addAll({
          'appointmentAt': Timestamp.fromDate(appointmentDateTime),
          'reminderSent': false,
        });
      }

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update(updateData);
    }
}