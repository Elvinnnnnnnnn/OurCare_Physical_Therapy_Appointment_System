import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum ReportRange {
    today,
    week,
    month,
    year,
    all,
  }

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends State<DoctorAppointmentsScreen> {
  int selectedTab = 0;

  final tabs = ['Pending', 'Upcoming', 'Completed', 'Cancelled'];

  ReportRange selectedRange = ReportRange.all;

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
    if (selectedTab == 2) return 'completed';
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

  Future<void> _showPrintOptions() async {
  showModalBottomSheet(
    context: context,
    builder: (_) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Today'),
            onTap: () {
              selectedRange = ReportRange.today;
              Navigator.pop(context);
              _printAppointmentsHistory();
            },
          ),
          ListTile(
            title: const Text('This Week'),
            onTap: () {
              selectedRange = ReportRange.week;
              Navigator.pop(context);
              _printAppointmentsHistory();
            },
          ),
          ListTile(
            title: const Text('This Month'),
            onTap: () {
              selectedRange = ReportRange.month;
              Navigator.pop(context);
              _printAppointmentsHistory();
            },
          ),
          ListTile(
            title: const Text('This Year'),
            onTap: () {
              selectedRange = ReportRange.year;
              Navigator.pop(context);
              _printAppointmentsHistory();
            },
          ),
          ListTile(
            title: const Text('All'),
            onTap: () {
              selectedRange = ReportRange.all;
              Navigator.pop(context);
              _printAppointmentsHistory();
            },
          ),
        ],
      );
    },
  );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _showPrintOptions,
          ),
        ],
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

  Future<void> _printAppointmentsHistory() async {
  if (doctorFirestoreId == null) return;

  Query query = FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorId', isEqualTo: doctorFirestoreId)
      .where('status', isEqualTo: getStatusFilter());

  DateTime now = DateTime.now();
  DateTime start;
  DateTime end;

  switch (selectedRange) {
    case ReportRange.today:
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end));
      break;

    case ReportRange.week:
      int weekday = now.weekday;
      start = now.subtract(Duration(days: weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      end = start.add(const Duration(days: 7));
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end));
      break;

    case ReportRange.month:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end));
      break;

    case ReportRange.year:
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year + 1, 1, 1);
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end));
      break;

    case ReportRange.all:
      break;
  }

  final snapshot =
      await query.orderBy('createdAt', descending: true).get();

  await Printing.layoutPdf(
    onLayout: (format) async {
      return _generatePdf(snapshot.docs);
    },
  );
}
  Future<Uint8List> _generatePdf(
    List<QueryDocumentSnapshot> appointments) async {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(
            margin: pw.EdgeInsets.all(32),
          ),
          build: (context) => [
            pw.Container(
              height: 6,
              color: PdfColor.fromHex('#1562E2'),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Appointments Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  DateTime.now().toString().split(' ').first,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Status: ${getStatusFilter().toUpperCase()}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Total: ${appointments.length}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfHeader('Patient'),
                    _pdfHeader('Date'),
                    _pdfHeader('Time'),
                    _pdfHeader('Status'),
                    _pdfHeader('Amount Paid'),
                  ],
                ),
                ...appointments.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return pw.TableRow(
                    children: [
                      _pdfCell((data['patientName'] ?? '').toString()),
                      _pdfCell((data['date'] ?? '').toString()),
                      _pdfCell((data['time'] ?? '').toString()),
                      _pdfCell((data['status'] ?? '').toString()),
                      _pdfCell((data['amountPaid'] ?? '').toString()),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      );

      return pdf.save();
    }

    pw.Widget _pdfHeader(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    pw.Widget _pdfCell(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: const pw.TextStyle(fontSize: 11),
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
    if (status == 'completed') return 'Completed';
    if (status == 'cancelled') return 'Cancelled';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final String paymentStatus =
      (appointment['paymentStatus'] ?? 'unpaid').toString();
    final String status =
      (appointment['status'] ?? 'pending').toString();
    final String patientId =
      (appointment['userId'] ?? '').toString();

    return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentDetailsScreen(
            appointment: appointment,
          ),
        ),
      );
    },
  child: Container(
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
                     (appointment['patientName'] ?? 'Unknown').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kDarkBlue,
                      ),
                    ),
                    Text(
                      (appointment['categoryName'] ?? '').toString(),
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

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: paymentStatus == 'approved'
                  ? Colors.green.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              paymentStatus == 'approved'
                  ? 'Payment Approved'
                  : 'Payment For Verification',
              style: TextStyle(
                color: paymentStatus == 'approved'
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 14),

          /// DATE & TIME
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: kPrimaryBlue),
              const SizedBox(width: 6),
              Text((appointment['date'] ?? '').toString()),
              const SizedBox(width: 18),
              const Icon(Icons.access_time,
                  size: 16, color: kPrimaryBlue),
              const SizedBox(width: 6),
              Text((appointment['time'] ?? '').toString()),
            ],
          ),

          /// ACTIONS
          if (appointment['paymentId'] != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Payment Screenshot'),
              onPressed: () async {
                final paymentId = appointment['paymentId'];
                if (paymentId == null) return;

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

        /// APPROVE / REJECT ONLY WHEN PENDING
        /// APPROVE / REJECT ONLY WHEN PENDING
          if (status == 'pending' && paymentStatus == 'for_verification') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus('cancelled'),
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
                    onPressed: () => _updateStatus('approved'),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],

          /// 🔵 FINISH BUTTON WHEN APPROVED
          if (status == 'approved') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _updateStatus('completed'),
                child: const Text('Finish Session'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
    Future<void> _updateStatus(String newStatus) async {
    final Map<String, dynamic> updateData = {
      'status': newStatus,
    };

    if (newStatus == 'approved') {
      final String dateStr =
        (appointment['date'] ?? '').toString();
      final String rawTime =
        (appointment['time'] ?? '').toString();
      final String startTime = rawTime.split('–').first.trim();
      final parts = dateStr.split('-');
      final int year = int.parse(parts[0]);
      final int month = int.parse(parts[1]);
      final int day = int.parse(parts[2]);

      final timeParts = startTime.split(' ');
      final clock = timeParts[0];
      final meridiem = timeParts[1];

      final hm = clock.split(':');
      int hour = int.parse(hm[0]);
      final int minute = int.parse(hm[1]);

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
        'reminderScheduled': false,
        'paymentStatus': 'approved',
      });

      // 🔥 ALSO UPDATE PAYMENT DOCUMENT
      if (appointment['paymentId'] != null) {
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(appointment['paymentId'])
            .update({
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    
    if (newStatus == 'completed') {
      updateData.addAll({
        'completedAt': FieldValue.serverTimestamp(),
      });
    }

    if (newStatus == 'cancelled') {
      if (appointment['paymentId'] != null) {
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(appointment['paymentId'])
            .update({
          'status': 'rejected',
        });
      }
    }

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update(updateData);
  }

    Future<void> _viewPaymentProof(BuildContext context) async {
    final paymentId = appointment['paymentId'];
    if (paymentId == null) return;

    final paymentSnap = await FirebaseFirestore.instance
        .collection('payments')
        .doc(paymentId)
        .get();

    final paymentData = paymentSnap.data();
    if (paymentData == null) return;

    final String? imageUrl = paymentData['screenshotUrl'];

    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No screenshot uploaded')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

class AppointmentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final String patientName =
        (appointment['patientName'] ?? 'Unknown').toString();
    final String amountPaid =
      (appointment['amountPaid'] ?? '').toString();
    final String category =
        (appointment['categoryName'] ?? '').toString();
    final String date =
        (appointment['date'] ?? '').toString();
    final String time =
        (appointment['time'] ?? '').toString();
    final String status =
        (appointment['status'] ?? '').toString();
    final String doctorId =
        (appointment['doctorId'] ?? '').toString();
    final String paymentStatus =
        (appointment['paymentStatus'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printDetails(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _sectionTitle('Patient Information'),
            _infoCard([
              _infoRow('Patient Name', patientName),
              _infoRow('Amount Paid', amountPaid),
              _infoRow('Doctor ID', doctorId),
            ]),

            const SizedBox(height: 20),

            _sectionTitle('Appointment Information'),
            _infoCard([
              _infoRow('Category', category),
              _infoRow('Date', date),
              _infoRow('Time', time),
              _infoRow('Status', status),
              _infoRow('Payment Status', paymentStatus),
            ]),

          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _printDetails() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Appointment Details',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),

          _pdfRow('Patient Name', appointment['patientName'] ?? ''),
          _pdfRow('Amount Paid', appointment['amountPaid'] ?? ''),
          _pdfRow('Doctor ID', appointment['doctorId'] ?? ''),
          _pdfRow('Category', appointment['categoryName'] ?? ''),
          _pdfRow('Date', appointment['date'] ?? ''),
          _pdfRow('Time', appointment['time'] ?? ''),
          _pdfRow('Status', appointment['status'] ?? ''),
          _pdfRow('Payment Status', appointment['paymentStatus'] ?? ''),

          pw.SizedBox(height: 30),
          pw.Text(
            'Generated on ${DateTime.now().toString().split(" ").first}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.Widget _pdfRow(String label, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(value.toString()),
          ),
        ],
      ),
    );
  }
}