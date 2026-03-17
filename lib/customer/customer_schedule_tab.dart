import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reschedule_appointment_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> openGoogleReview() async {
    final Uri url = Uri.parse(
      'https://share.google/uiVInXqswFFcRRkdI',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not open review link';
    }
  }

  String _getInitial(String name) {
    if (name.trim().isEmpty) return 'D';
    return name.trim()[0].toUpperCase();
  }

  Color statusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    if (status == 'completed') return Colors.grey;
    return Colors.orange;
  }

  String statusText(String status) {
    if (status == 'approved') return 'Ongoing';
    if (status == 'completed') return 'Completed';
    if (status == 'cancelled') return 'Cancelled';
    return 'Pending';
  }

  Future<String?> _loadDoctorPhoto(String doctorId) async {
    final snap = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();

    return snap.data()?['photoUrl'];
  }

  @override
  Widget build(BuildContext context) {

    final String doctorName =
        (appointment['doctorName'] ?? 'Doctor').toString();

    final String categoryName =
        (appointment['categoryName'] ?? 'Service').toString();

    final String status =
        (appointment['status'] ?? 'pending').toString();

    final String doctorId =
        (appointment['doctorId'] ?? '').toString();

    final String date =
        (appointment['date'] ?? 'No date').toString();

    final String time =
        (appointment['time'] ?? 'No time').toString();

    final String paymentMethod =
        (appointment['paymentMethod'] ?? '').toString();

    final String? paymentId = appointment['paymentId'];

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

          Row(
            children: [

              FutureBuilder<String?>(
                future: doctorId.isEmpty
                    ? null
                    : _loadDoctorPhoto(doctorId),
                builder: (context, snapshot) {

                  final photoUrl = snapshot.data;

                  return CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            _getInitial(doctorName),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
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
                      doctorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kDarkBlue,
                      ),
                    ),

                    Text(
                      categoryName,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              paymentMethod == 'cash'
                  ? 'Payment Method: Cash'
                  : 'Payment Method: GCash',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [

              const Icon(
                Icons.calendar_today,
                size: 16,
                color: kPrimaryBlue,
              ),

              const SizedBox(width: 6),

              Text(date),

              const SizedBox(width: 18),

              const Icon(
                Icons.access_time,
                size: 16,
                color: kPrimaryBlue,
              ),

              const SizedBox(width: 6),

              Text(time),
            ],
          ),

          if (paymentId != null) ...[

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.receipt_long,
                  color: kPrimaryBlue,
                ),
                label: const Text(
                  'View Payment Screenshot',
                  style: TextStyle(color: kPrimaryBlue),
                ),
                onPressed: () async {

                  final paymentSnap = await FirebaseFirestore
                      .instance
                      .collection('payments')
                      .doc(paymentId)
                      .get();

                  final paymentData = paymentSnap.data();
                  final screenshotUrl =
                      paymentData?['screenshotUrl'];

                  if (screenshotUrl == null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text('No screenshot found'),
                      ),
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
                      builder: (_) =>
                          RescheduleAppointmentScreen(
                        appointmentId: appointmentId,
                        appointmentData: appointment,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          if (status == 'completed') ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(
                Icons.reviews,
                color: kPrimaryBlue,
              ),
              label: const Text(
                'Leave a Review',
                style: TextStyle(color: kPrimaryBlue),
              ),
              onPressed: openGoogleReview,
            ),
          ],
        ],
      ),
    );
  }
}