import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

  Future<void> _generatePdf(String filter) async {

    final pdf = pw.Document();

    Query query = FirebaseFirestore.instance.collection('appointments');

    final snapshot = await query.get();

    final data = snapshot.docs.map((e) {
      final d = e.data() as Map<String, dynamic>;

      return {
        "patient": (d['patientName'] ?? '').toString(),
        "doctor": (d['doctorName'] ?? '').toString(),
        "date": (d['date'] ?? '').toString(),
        "time": (d['time'] ?? '').toString(),
        "status": (d['status'] ?? '').toString(),
      };
    }).toList();

    if (data.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (_) => pw.Center(
            child: pw.Text('No appointments found'),
          ),
        ),
      );
    } else {
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [

            pw.Text(
              'Appointments Report',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Text('Doctor: All'),
            pw.Text('Range: ${_getFilterLabel(filter)}'),
            pw.Text('Total Appointments: ${data.length}'),

            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              headers: ['Patient', 'Doctor', 'Date', 'Time', 'Status'],
              data: data.map((e) => [
                e['patient'],
                e['doctor'],
                e['date'],
                e['time'],
                e['status'],
              ]).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
            ),

          ],
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  List<pw.Widget> _tableHeader() {
    return [
      _header('Patient'),
      _header('Doctor'),
      _header('Date'),
      _header('Time'),
      _header('Status'),
    ];
  }

  pw.Widget _header(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  pw.Widget _cell(dynamic text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        (text ?? '').toString(),
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'year':
        return 'This Year';
      default:
        return 'All';
    }
  }

class _AdminAppointmentsScreenState
    extends State<AdminAppointmentsScreen> {

  int selectedTab = 0;
  String searchQuery = "";

  String? selectedDoctorId;
  String selectedDoctorName = "All";

  List<Map<String, dynamic>> doctors = [];

  final tabs = ['Pending', 'Upcoming', 'Completed', 'Cancelled'];

  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kDarkBlue = Color(0xFF001C99);

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('activated', isEqualTo: true)
        .get();

    doctors = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "id": doc.id,
        "name": data['name'] ?? "Doctor",
      };
    }).toList();

    setState(() {});
  }

  String getStatusFilter() {
    if (selectedTab == 0) return 'pending';
    if (selectedTab == 1) return 'approved';
    if (selectedTab == 2) return 'completed';
    return 'cancelled';
  }

  void _showPrintOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            _sheetItem(context, "Today", "today"),
            _sheetItem(context, "This Week", "week"),
            _sheetItem(context, "This Month", "month"),
            _sheetItem(context, "This Year", "year"),
            _sheetItem(context, "All", "all"),

          ],
        );
      },
    );
  }

  Widget _sheetItem(BuildContext context, String title, String filter) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        _generatePdf(filter);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          /// TOP BAR
          Row(
            children: [
              DropdownButton<String>(
                value: selectedDoctorName,
                items: [
                  const DropdownMenuItem(
                    value: "All",
                    child: Text("All Therapist"),
                  ),
                  ...doctors.map((doctor) {
                    return DropdownMenuItem<String>(
                      value: doctor["name"] as String,
                      child: Text(doctor["name"] as String),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  if (value == "All") {
                    selectedDoctorName = "All";
                    selectedDoctorId = null;
                  } else {
                    final doctor =
                        doctors.firstWhere((d) => d["name"] == value);
                    selectedDoctorName = doctor["name"];
                    selectedDoctorId = doctor["id"];
                  }
                  setState(() {});
                },
              ),

              const Spacer(),

              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () {
                  _showPrintOptions(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// SEARCH
          TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search patient...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// TABS
          Row(
            children: List.generate(tabs.length, (index) {
              final selected = selectedTab == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    selectedTab = index;
                    setState(() {});
                  },
                  child: AnimatedScale(
                    scale: selected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected ? kPrimaryBlue : kSoftBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          color: selected ? Colors.white : kDarkBlue,
                          fontWeight: FontWeight.w600,
                        ),
                        child: Center(
                          child: Text(tabs[index]),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          /// LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: (() {
                Query query = FirebaseFirestore.instance.collection('appointments');

                if (selectedTab == 1) {
                  // Upcoming tab
                  query = query.where('status', whereIn: ['approved', 'ongoing']);
                } else {
                  query = query.where('status', isEqualTo: getStatusFilter());
                }

                if (selectedDoctorId != null) {
                  query = query.where('doctorId',
                      isEqualTo: selectedDoctorId);
                }

                return query.snapshots();
              })(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['patientName'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No appointments"));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _AdminAppointmentCard(
                      appointment: data,
                      appointmentId: doc.id,
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

/// CARD UI
class _AdminAppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String appointmentId;

  const _AdminAppointmentCard({
    required this.appointment,
    required this.appointmentId,
  });

  static const Color primary = Color(0xFF1562E2);
  static const Color textDark = Color(0xFF1F2937);

  Color statusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    if (status == 'completed') return Colors.blue;
    if (status == 'ongoing') return Colors.green;
    return Colors.orange;
  }

  String statusText(String status) {
    if (status == 'approved') return 'Approved';
    if (status == 'completed') return 'Completed';
    if (status == 'cancelled') return 'Cancelled';
    if (status == 'ongoing') return 'Ongoing';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final status = (appointment['status'] ?? 'pending').toString();
    final paymentStatus =
        (appointment['paymentStatus'] ?? 'unpaid').toString();

    final name = (appointment['patientName'] ?? 'U').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [

          /// TOP ROW
          Row(
            children: [

              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(appointment['userId'])
                    .get(),
                builder: (context, snapshot) {

                  String? photoUrl;

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
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    Text(
                      appointment['doctorName'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      appointment['categoryName'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText(status),
                  style: TextStyle(
                    color: statusColor(status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// INFO ROW
          Row(
            children: [

              _tag(
                text: paymentStatus == 'approved'
                    ? 'Payment Approved'
                    : paymentStatus == 'cash_pending'
                        ? 'Cash Payment'
                        : 'Verification',
                color: paymentStatus == 'approved'
                    ? Colors.green
                    : Colors.orange,
              ),

              const SizedBox(width: 8),

              _tag(
                text: appointment['paymentMethod'] == 'cash'
                    ? 'Cash'
                    : 'GCash',
                color: Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// DATE TIME
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 6),
              Text(appointment['date'] ?? ''),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 6),
              Text(appointment['time'] ?? ''),
            ],
          ),

          const SizedBox(height: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// VIEW BUTTON
              if (appointment['paymentId'] != null &&
                  appointment['paymentMethod'] != 'cash')
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt),
                  label: const Text('View'),
                  onPressed: () async {
                    final paymentSnap = await FirebaseFirestore.instance
                        .collection('payments')
                        .doc(appointment['paymentId'])
                        .get();

                    final url = paymentSnap.data()?['screenshotUrl'];
                    if (url == null) return;

                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Image.network(url),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 10),

              /// PENDING
              if (status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus('cancelled'),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus('approved'),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),

              /// APPROVED
              if (status == 'approved')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStatus('ongoing'),
                  child: const Text('Start Session'),
                ),
              ),
              if (status == 'ongoing')
                SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _updateStatus('completed'),
                  child: const Text('Finish Session'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _tag({required String text, required Color color}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    final Map<String, dynamic> updateData = {
      'status': newStatus,
    };

    if (newStatus == 'approved') {
      updateData['approvedBy'] = 'admin';

      final String dateStr =
          (appointment['date'] ?? '').toString();
      final String rawTime =
          (appointment['time'] ?? '').toString();

      final String startTime =
          rawTime.split(' - ').first.trim();

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

      updateData['appointmentAt'] =
          Timestamp.fromDate(appointmentDateTime);
      updateData['reminderScheduled'] = false;
    }

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update(updateData);
  }
}