import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reschedule_appointment_screen.dart';

class CustomerScheduleTab extends StatefulWidget {
  const CustomerScheduleTab({super.key});

  @override
  State<CustomerScheduleTab> createState() => _CustomerScheduleTabState();
}

class _CustomerScheduleTabState extends State<CustomerScheduleTab> {
  int selectedTab = 0;

  final tabs = ['Upcoming', 'Completed', 'Cancelled'];

  // Brand colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  String? getStatusFilter() {
    if (selectedTab == 1) return 'completed';
    if (selectedTab == 2) return 'cancelled';
    return null; // Upcoming
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Schedule',
          style: TextStyle(
            color: kDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kDarkBlue),
      ),
      body: Column(
        children: [
          /// SEGMENTED TABS
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

          /// APPOINTMENTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('userId', isEqualTo: user!.uid)
                  .where('status',
                    whereIn: selectedTab == 0
                        ? ['pending', 'approved']
                        : [getStatusFilter()])
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No appointments found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final appointments = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appt =
                        appointments[index].data() as Map<String, dynamic>;

                    return AppointmentCard(
                      appointment: appt,
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
class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String appointmentId;

  const AppointmentCard({
    super.key,
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
    if (status == 'approved') return 'Ongoing';
    if (status == 'completed') return 'Completed';
    if (status == 'cancelled') return 'Cancelled';
    return 'Pending';
  }

  /// 🔹 FETCH DOCTOR PHOTO (MINIMAL)
  Future<String?> _loadDoctorPhoto(String doctorId) async {
    final snap = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();

    return snap.data()?['photoUrl'];
  }

  @override
  Widget build(BuildContext context) {
    final status = appointment['status'];
    final rating = appointment['rating'];
    final doctorId = appointment['doctorId'];

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
              FutureBuilder<String?>(
                future: _loadDoctorPhoto(doctorId),
                builder: (context, snapshot) {
                  final photoUrl = snapshot.data;
                  return CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : const AssetImage('assets/placeholder-400x400.jpg')
                            as ImageProvider,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['doctorName'],
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

          const SizedBox(height: 14),

          /// VIEW PAYMENT SCREENSHOT
          if (appointment['paymentId'] != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long, color: kPrimaryBlue),
                label: const Text(
                  'View Payment Screenshot',
                  style: TextStyle(color: kPrimaryBlue),
                ),
                onPressed: () async {
                  final paymentId = appointment['paymentId'];

                  final paymentSnap = await FirebaseFirestore.instance
                      .collection('payments')
                      .doc(paymentId)
                      .get();

                  final paymentData = paymentSnap.data();
                  final screenshotUrl = paymentData?['screenshotUrl'];

                  if (screenshotUrl == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No screenshot found')),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.black,
                      insetPadding: const EdgeInsets.all(10),
                      child: InteractiveViewer(
                        child: Image.network(screenshotUrl),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          /// RESCHEDULE
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Reschedule'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RescheduleAppointmentScreen(
                        appointmentId: appointmentId,
                        appointmentData: appointment,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          /// RATE DOCTOR
            if (status == 'completed' && rating == null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.star, color: kPrimaryBlue),
              label: const Text('Rate Doctor'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => RateDoctorDialog(
                    appointmentId: appointmentId,
                    doctorId: doctorId,
                  ),
                );
              },
            ),
          ],

          /// SHOW RATING
          if (rating != null) ...[
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ===============================
/// RATE DOCTOR DIALOG
/// ===============================
class RateDoctorDialog extends StatefulWidget {
  final String appointmentId;
  final String doctorId;

  const RateDoctorDialog({
    super.key,
    required this.appointmentId,
    required this.doctorId,
  });

  @override
  State<RateDoctorDialog> createState() => _RateDoctorDialogState();
}

class _RateDoctorDialogState extends State<RateDoctorDialog> {
  int rating = 5;
  bool loading = false;

  Future<void> submit() async {
    setState(() => loading = true);

    final apptRef = FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId);

    final doctorRef = FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctorId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final doctorSnap = await tx.get(doctorRef);

      final oldAvg =
          (doctorSnap.data()?['averageRating'] ?? 0).toDouble();
      final total =
          (doctorSnap.data()?['totalRatings'] ?? 0) as int;

      final newTotal = total + 1;
      final newAvg = ((oldAvg * total) + rating) / newTotal;

      tx.update(apptRef, {'rating': rating});
      tx.update(doctorRef, {
        'averageRating': newAvg,
        'totalRatings': newTotal,
      });
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Doctor'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          5,
          (i) => IconButton(
            icon: Icon(
              i < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () => setState(() => rating = i + 1),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: loading ? null : submit,
          child: loading
              ? const CircularProgressIndicator()
              : const Text('Submit'),
        ),
      ],
    );
  }
}
