import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

  enum ReportRange {
    today,
    week,
    month,
    year,
    all,
  }

  String searchQuery = "";

class _AdminAppointmentsScreenState
    extends State<AdminAppointmentsScreen> {

  int selectedTab = 0;
  
  String? selectedDoctorId;
  String selectedDoctorName = "All";
  ReportRange selectedRange = ReportRange.all;
  List<Map<String, String>> doctors = [];

  Future<void> _loadDoctors() async {

    final snapshot =
        await FirebaseFirestore.instance
            .collection('doctors')
            .where('activated', isEqualTo: true)
            .get();

    List<Map<String, String>> list = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      list.add({
        "id": doc.id,
        "name": data['name'] ?? "Doctor",
      });
    }

    setState(() {
      doctors = list;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDoctors();
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
                _printAppointmentsReport();
              },
            ),

            ListTile(
              title: const Text('This Week'),
              onTap: () {
                selectedRange = ReportRange.week;
                Navigator.pop(context);
                _printAppointmentsReport();
              },
            ),

            ListTile(
              title: const Text('This Month'),
              onTap: () {
                selectedRange = ReportRange.month;
                Navigator.pop(context);
                _printAppointmentsReport();
              },
            ),

            ListTile(
              title: const Text('This Year'),
              onTap: () {
                selectedRange = ReportRange.year;
                Navigator.pop(context);
                _printAppointmentsReport();
              },
            ),

            ListTile(
              title: const Text('All'),
              onTap: () {
                selectedRange = ReportRange.all;
                Navigator.pop(context);
                _printAppointmentsReport();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _printAppointmentsReport() async {

    Query query = FirebaseFirestore.instance
        .collection('appointments')
        .where('status', isEqualTo: getStatusFilter());

    if (selectedDoctorId != null) {
      query = query.where('doctorId', isEqualTo: selectedDoctorId);
    }

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

    final snapshot = await query
      .orderBy('createdAt', descending: true)
      .get();

    await Printing.layoutPdf(
      onLayout: (format) async {
        return _generatePdf(snapshot.docs);
      },
    );
  }

  String getRangeLabel() {
    switch (selectedRange) {
      case ReportRange.today:
        return "Today";
      case ReportRange.week:
        return "This Week";
      case ReportRange.month:
        return "This Month";
      case ReportRange.year:
        return "This Year";
      case ReportRange.all:
        return "All";
    }
  }

  Future<Uint8List> _generatePdf(
    List<QueryDocumentSnapshot> appointments) async {

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [

          pw.Text(
            'Appointments Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 6),

          pw.Text(
            'Doctor: $selectedDoctorName',
            style: const pw.TextStyle(fontSize: 12),
          ),

          pw.Text(
            'Range: ${getRangeLabel()}',
            style: const pw.TextStyle(fontSize: 12),
          ),

          pw.Text(
            'Total Appointments: ${appointments.length}',
            style: const pw.TextStyle(fontSize: 12),
          ),

          pw.SizedBox(height: 20),

          pw.Table(
            border: pw.TableBorder.all(),
            children: [

              pw.TableRow(
                children: [
                  _pdfHeader('Patient'),
                  _pdfHeader('Doctor'),
                  _pdfHeader('Date'),
                  _pdfHeader('Time'),
                  _pdfHeader('Status'),
                ],
              ),

              ...appointments.map((doc) {

                final data = doc.data() as Map<String, dynamic>;

                return pw.TableRow(
                  children: [
                    _pdfCell(data['patientName'] ?? ''),
                    _pdfCell(data['doctorName'] ?? ''),
                    _pdfCell(data['date'] ?? ''),
                    _pdfCell(data['time'] ?? ''),
                    _pdfCell(data['status'] ?? ''),
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

  final tabs = ['Pending', 'Upcoming', 'Completed', 'Cancelled'];

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  String getStatusFilter() {
    if (selectedTab == 0) return 'pending';
    if (selectedTab == 1) return 'approved';
    if (selectedTab == 2) return 'completed';
    return 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [

            const SizedBox(width: 8),

            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDoctorName,
                items: [
                  const DropdownMenuItem(
                    value: "All",
                    child: Text("All Doctors"),
                  ),

                  ...doctors.map((doctor) {
                    return DropdownMenuItem(
                      value: doctor["name"],
                      child: Text(doctor["name"]!),
                    );
                  }).toList(),
                ],
                onChanged: (value) {

                  if (value == "All") {
                    setState(() {
                      selectedDoctorName = "All";
                      selectedDoctorId = null;
                    });
                    return;
                  }

                  final doctor = doctors.firstWhere(
                    (d) => d["name"] == value,
                  );

                  setState(() {
                    selectedDoctorName = doctor["name"]!;
                    selectedDoctorId = doctor["id"];
                  });
                },
              ),
            ),

            const Spacer(),

            IconButton(
              icon: const Icon(Icons.print, color: kDarkBlue),
              onPressed: _showPrintOptions,
            ),

            const SizedBox(width: 8),
          ],
        ),
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search patient name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// TABS
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
                      onTap: () {
                        setState(() {
                          selectedTab = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? kPrimaryBlue
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Text(
                          tabs[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : kDarkBlue,
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
              stream: (() {

                Query query = FirebaseFirestore.instance
                    .collection('appointments')
                    .where('status', isEqualTo: getStatusFilter());

                if (selectedDoctorId != null) {
                  query = query.where('doctorId', isEqualTo: selectedDoctorId);
                }

                return query.snapshots();

              })(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allAppointments = snapshot.data!.docs;

                final appointments = allAppointments.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['patientName'] ?? '').toString().toLowerCase();

                  return name.contains(searchQuery);
                }).toList();

                if (appointments.isEmpty) {
                  return const Center(
                    child: Text(
                      "No appointments found",
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

                    return _AdminAppointmentCard(
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

class _AdminAppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String appointmentId;

  const _AdminAppointmentCard({
    required this.appointment,
    required this.appointmentId,
  });

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  Color statusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    if (status == 'completed') return Colors.blue;
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

    final String status =
        (appointment['status'] ?? 'pending').toString();

    final String paymentStatus =
        (appointment['paymentStatus'] ?? 'unpaid').toString();

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

              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(appointment['userId'])
                    .get(),
                builder: (context, snapshot) {

                  String? photoUrl;

                  final String name =
                      (appointment['patientName'] ?? 'U').toString();

                  final String initial =
                      name.isNotEmpty ? name[0].toUpperCase() : 'U';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data =
                        snapshot.data!.data() as Map<String, dynamic>?;

                    photoUrl = data?['photoUrl'];
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      (appointment['patientName'] ?? 'Unknown')
                          .toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kDarkBlue,
                      ),
                    ),

                    Text(
                      (appointment['doctorName'] ?? '')
                          .toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                    Text(
                      (appointment['categoryName'] ?? '')
                          .toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
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

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: paymentStatus == 'approved'
                  ? Colors.green.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              paymentStatus == 'approved'
                  ? 'Payment Approved'
                  : paymentStatus == 'cash_pending'
                      ? 'Cash Payment'
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

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              appointment['paymentMethod'] == 'cash'
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

          if (appointment['paymentId'] != null &&
          appointment['paymentMethod'] != 'cash') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: const Text(
                    'View Payment Screenshot'),
                onPressed: () async {

                  final paymentId =
                      appointment['paymentId'];

                  final paymentSnap =
                      await FirebaseFirestore.instance
                          .collection('payments')
                          .doc(paymentId)
                          .get();

                  final paymentData =
                      paymentSnap.data();

                  final screenshotUrl =
                      paymentData?['screenshotUrl'];

                  if (screenshotUrl == null) return;

                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.black,
                      insetPadding:
                          const EdgeInsets.all(10),
                      child: InteractiveViewer(
                        child: Image.network(
                            screenshotUrl),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

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

          if (status == 'approved') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    _updateStatus('completed'),
                child: const Text('Finish Session'),
              ),
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
      updateData['approvedBy'] = 'admin';
    }

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update(updateData);
  }
}