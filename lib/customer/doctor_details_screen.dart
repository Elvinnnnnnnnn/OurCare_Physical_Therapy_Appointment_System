import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'customer_home.dart';
import 'payment_screen.dart';
import '../services/notification_service.dart';

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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTime;

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  Map<String, dynamic> get availability {
    final data = widget.doctorData['availability'];

    if (data == null || data is! Map) return {};

    final Map<String, dynamic> result = {};

    data.forEach((day, value) {
      if (value is List) {
        result[day] = {
          'enabled': true,
          'slots': value.map((slot) {
            final map = Map<String, dynamic>.from(slot);
            return {
              'start': map['start'],
              'end': map['end'],
              'active': true,
            };
          }).toList(),
        };
      } else if (value is Map) {
        result[day] = {
          'enabled': value['enabled'] ?? true,
          'slots': (value['slots'] as List? ?? []).map((slot) {
            final map = Map<String, dynamic>.from(slot);
            return {
              'start': map['start'],
              'end': map['end'],
              'active': map['active'] ?? true,
            };
          }).toList(),
        };
      }
    });

    return result;
  }

  String weekdayKey(DateTime day) {
    return DateFormat('EEEE').format(day).toLowerCase();
  }

  List<String> availableRangesForDay(DateTime day) {
    if (availability.isEmpty) return [];

    final key = weekdayKey(day);
    final dayData = availability[key];

    if (dayData == null) return [];
    if (dayData['enabled'] != true) return [];

    final List slots = dayData['slots'] ?? [];

    return slots
        .where((s) => s['active'] == true)
        .map<String>((s) => '${s['start']} - ${s['end']}')
        .toList();
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

    final startTime = _selectedTime!.split(' - ').first;
    final parsed = DateFormat('hh:mm a').parse(startTime);

    final appointmentDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      parsed.hour,
      parsed.minute,
    );

    final alreadyBooked =
    await isTimeBooked(_selectedDay!, _selectedTime!);

    if (alreadyBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This time slot is already booked'),
        ),
      );
      return;
    }

    final paymentRef =
        await FirebaseFirestore.instance.collection('payments').add({
      'userId': user.uid,
      'doctorId': widget.doctorId,
      'doctorName': doctor['name'],
      'categoryName': doctor['categoryName'],
      'amount': price,
      'currency': 'PHP',
      'date':
          '${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}',
      'time': _selectedTime,
      'dateTime': Timestamp.fromDate(appointmentDateTime),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          paymentId: paymentRef.id,
        ),
      ),
    );
  }

  Future<bool> isTimeBooked(DateTime day, String timeRange) async {
    final dateString = '${day.year}-${day.month}-${day.day}';

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('date', isEqualTo: dateString)
        .where('time', isEqualTo: timeRange)
        .where('status', whereIn: ['pending', 'approved', 'completed'])
        .get();

    return snapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctorData;
    final rating = (doctor['averageRating'] ?? 0).toDouble();
    final price = (doctor['consultationPrice'] ?? 0).toInt();
    final formattedPrice = NumberFormat('#,###').format(price);

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
                        : const AssetImage(
                                'assets/placeholder-400x400.jpg')
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
                          style:
                              const TextStyle(color: kDarkBlue),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Consultation Fee: ₱$formattedPrice',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.orange,
                                size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600),
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
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),

              headerStyle: const HeaderStyle(
                formatButtonVisible: false, // 🔥 removes 2 weeks / month
                titleCentered: true,
              ),

              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },

              calendarFormat: CalendarFormat.month,

              enabledDayPredicate: (day) {
                final key = weekdayKey(day);
                final dayData = availability[key];
                if (dayData == null) return false;
                return dayData['enabled'] == true;
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: times.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
              ),
              itemBuilder: (context, index) {
              final time = times[index];

              return FutureBuilder<bool>(
                future: isTimeBooked(_selectedDay!, time),
                builder: (context, snapshot) {
                  final booked = snapshot.data ?? false;
                  final selected = time == _selectedTime;

                  return ChoiceChip(
                    label: Text(
                      booked ? '$time (Booked)' : time,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: selected,
                    selectedColor: kPrimaryBlue,
                    disabledColor: Colors.grey.shade300,
                    onSelected: booked
                        ? null
                        : (_) => setState(() => _selectedTime = time),
                  );
                },
              );
            },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
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