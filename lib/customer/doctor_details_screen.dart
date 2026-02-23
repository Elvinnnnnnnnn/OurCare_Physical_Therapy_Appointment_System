import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'customer_home.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const DoctorDetailsScreen({
    super.key,
    required this.doctorId,
    required this.doctorData,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  List<String> bookedTimes = [];

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTime;

  final List<String> fallbackTimes = [
    '09:00 AM – 10:00 AM',
    '12:00 PM – 01:00 PM',
    '04:00 PM – 05:00 PM',
  ];

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  Map<String, dynamic> get availability {
    final data = widget.doctorData['availability'];
    if (data == null || data is! Map) return {};
    return Map<String, dynamic>.from(data);
  }

  String weekdayKey(DateTime day) {
    return DateFormat('EEEE').format(day).toLowerCase();
  }

  List<String> availableRangesForDay(DateTime day) {
    if (availability.isEmpty) return fallbackTimes;

    final key = weekdayKey(day);
    final rawSlots = availability[key];

    if (rawSlots == null || rawSlots is! List || rawSlots.isEmpty) {
      return fallbackTimes;
    }

    final List<String> ranges = [];

    for (final rawSlot in rawSlots) {
      final slot = Map<String, dynamic>.from(rawSlot);
      final start = slot['start'];
      final end = slot['end'];

      if (start == null || end == null) continue;
      ranges.add('$start – $end');
    }

    return ranges.isEmpty ? fallbackTimes : ranges;
  }

  Future<void> openChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doctorAuthUid = widget.doctorData['userId'];
    if (doctorAuthUid == null) return;

    final chatId = '${user.uid}_$doctorAuthUid';

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'customerId': user.uid,
      'doctorId': doctorAuthUid,
      'doctorName': widget.doctorData['name'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerHome(initialIndex: 1),
      ),
    );
  }

  Future<void> bookAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_selectedDay == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date & time')),
      );
      return;
    }

    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    await FirebaseFirestore.instance.collection('appointments').add({
      'userId': user.uid,
      'patientName': userSnap['fullName'],
      'patientEmail': userSnap['email'],
      'doctorId': widget.doctorId,
      'doctorName': widget.doctorData['name'],
      'categoryName': widget.doctorData['categoryName'],
      'date':
          '${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}',
      'time': _selectedTime,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment booked successfully')),
    );

    Navigator.pop(context);
  }

  Future<void> startPayment() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  if (_selectedDay == null || _selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select date & time')),
    );
    return;
  }

  final doctor = widget.doctorData;
  final price = doctor['consultationPrice'] ?? 0;

  final paymentRef =
      await FirebaseFirestore.instance.collection('payments').add({
    'userId': user.uid,
    'doctorId': widget.doctorId,
    'doctorName': doctor['name'],
    'amount': price,
    'currency': 'PHP',
    'date':
        '${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}',
    'time': _selectedTime,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PaymentScreen(paymentId: paymentRef.id),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctorData;
    final rating = (doctor['averageRating'] ?? 0).toDouble();
    final price = (doctor['consultationPrice'] ?? 0).toInt();
    final currency = doctor['currency'] ?? 'PHP';


    final times = _selectedDay == null
        ? <String>[]
        : availableRangesForDay(_selectedDay!);

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkBlue),
        title: const Text(
          'Doctor Details',
          style: TextStyle(color: kDarkBlue),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSoftBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: doctor['photoUrl'] != null
                        ? NetworkImage(doctor['photoUrl'])
                        : const AssetImage('assets/placeholder-400x400.jpg')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kDarkBlue,
                          ),
                        ),
                        Text(
                            doctor['categoryName'],
                            style: const TextStyle(color: kDarkBlue),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Consultation Fee: ₱$price',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBlue,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.orange, size: 16),

                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message,
                        color: kPrimaryBlue),
                    onPressed: openChat,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 📅 ONLY CHANGE IS HERE
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),
              enabledDayPredicate: (day) {
                if (availability.isEmpty) return true;
                final key = weekdayKey(day);
                final slots = availability[key];
                return slots != null && slots.isNotEmpty;
              },
              onDaySelected: (day, focusedDay) {
                setState(() {
                  _selectedDay = day;
                  _focusedDay = focusedDay;
                  _selectedTime = null;
                });
              },
            ),

            const SizedBox(height: 24),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: times.map((time) {
                final selected = time == _selectedTime;

                return ChoiceChip(
                  label: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: selected,
                  selectedColor: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) =>
                      setState(() => _selectedTime = time),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: startPayment,
                child: const Text(
                  'Make an Appointment',
                  style: TextStyle(color: kWhite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
