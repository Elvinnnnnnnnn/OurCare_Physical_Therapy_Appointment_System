import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'payment_screen.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  final bool requirePayment;

  const RescheduleAppointmentScreen({
    super.key,
    required this.appointmentId,
    required this.appointmentData,
    required this.requirePayment,
  });

  @override
  State<RescheduleAppointmentScreen> createState() =>
      _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState
    extends State<RescheduleAppointmentScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTime;
  bool _showSlots = false;
  List<String> bookedTimes = [];

  Map<String, dynamic> doctorData = {};
  bool loadingDoctor = true;

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  Future<void> loadDoctor() async {
    final doctorId = widget.appointmentData['doctorId'];

    if (doctorId == null || doctorId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid doctor data')),
      );
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();

    if (doc.exists) {
      setState(() {
        final data = doc.data();

        if (data == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor data not found')),
          );
          return;
        }

        doctorData = data;
        loadingDoctor = false;
      });
    }
  }

  Map<String, dynamic> get availability {
    final data = doctorData['availability'];

    if (data == null || data is! Map) return {};

    return Map<String, dynamic>.from(data);
  }

  String weekdayKey(DateTime day) {
    return DateFormat('EEEE').format(day).toLowerCase();
  }

  List<DateTime> holidays = [];

  Future<void> loadBookedTimes(DateTime day) async {

    final doctorId = widget.appointmentData['doctorId'];

    final date = '${day.year}-${day.month}-${day.day}';

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: date)
        .get();

    bookedTimes = snapshot.docs
        .map((doc) => doc['time'] as String)
        .toList();

    setState(() {});
  }

  Future<void> loadHolidays() async {
    final year = DateTime.now().year;

    final response = await http.get(
      Uri.parse("https://date.nager.at/api/v3/PublicHolidays/$year/PH"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      holidays = data.map<DateTime>((holiday) {
        return DateTime.parse(holiday['date']);
      }).toList();
    } else {
      holidays = [];
    }
    setState(() {});
  }

  bool isHoliday(DateTime day) {
    return holidays.any((holiday) =>
        holiday.year == day.year &&
        holiday.month == day.month &&
        holiday.day == day.day);
  }

  @override
  void initState() {
    super.initState();
    loadDoctor();
    loadHolidays();
  }

  List<String> availableRangesForDay(DateTime day) {

    if (availability.isEmpty) return [];

    final key = weekdayKey(day);
    final rawData = availability[key];

    if (rawData == null) return [];
    if (rawData is! Map) return [];

    final dayData = rawData;

    if (dayData['enabled'] != true) return [];

    final start = dayData['start'];
    final end = dayData['end'];

    if (start == null || end == null) return [];

    final startTime = DateFormat('hh:mm a').parse(start);
    final endTime = DateFormat('hh:mm a').parse(end);

    List<String> slots = [];

    DateTime current = startTime;

    while (current.isBefore(endTime)) {

      final next = current.add(const Duration(hours: 1));

      if (next.isAfter(endTime)) break;

      final startFormatted = DateFormat('hh:mm a').format(current);
      final endFormatted = DateFormat('hh:mm a').format(next);

      final slot = '$startFormatted - $endFormatted';

      if (!bookedTimes.contains(slot)) {
        slots.add(slot);
      }

      current = next;
    }

    return slots;
  }

  Future<void> rescheduleAppointment() async {

    if (_selectedDay == null || _selectedTime == null) return;

    final doctorId = widget.appointmentData['doctorId'];

    final date = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    final existing = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: date)
        .where('time', isEqualTo: _selectedTime)
        .get();

    if (existing.docs.isNotEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This time slot is already booked'),
        ),
      );

      return;
    }

    final startTime = _selectedTime!.split(' - ').first;
    final parsed = DateFormat('hh:mm a').parse(startTime);

    final newDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      parsed.hour,
      parsed.minute,
    );

   if (widget.requirePayment) {

    double originalAmount =
    (widget.appointmentData['amountPaid'] ?? 0).toDouble();

    double rescheduleFee =
        (originalAmount * 0.30).roundToDouble();

    final paymentRef = await FirebaseFirestore.instance
        .collection('payments')
        .add({
      'userId': widget.appointmentData['userId'] ?? '',
      'doctorId': widget.appointmentData['doctorId'] ?? '',
      'doctorName': widget.appointmentData['doctorName'] ?? '',
      'categoryName': widget.appointmentData['categoryName'] ?? '',
      'amount': rescheduleFee,
      'currency': 'PHP',
      'date': date,
      'time': _selectedTime,
      'dateTime': Timestamp.fromDate(newDateTime),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'isReschedule': true,
      'originalAppointmentId': widget.appointmentId,
    });

    // ✅ LINK PAYMENT
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .update({
      'paymentId': paymentRef.id,
      'status': 'pending', // 🔥 THIS FIXES YOUR ISSUE
    });

  if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          paymentId: paymentRef.id,
        ),
      ),
    );

    return;
  }

  await FirebaseFirestore.instance
      .collection('appointments')
      .doc(widget.appointmentId)
      .update({
    'date': date,
    'time': _selectedTime,
    'dateTime': Timestamp.fromDate(newDateTime),
    'status': 'pending',
  });

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Appointment rescheduled')),
  );

  Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loadingDoctor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final times = _selectedDay == null
        ? <String>[]
        : availableRangesForDay(_selectedDay!);

    final range = _selectedDay == null
      ? null
      : times.isNotEmpty
          ? "${times.first.split(' - ').first} - ${times.last.split(' - ').last}"
          : null;

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkBlue),
        title: const Text(
          'Reschedule Appointment',
          style: TextStyle(color: kDarkBlue),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select new date',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,

              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),

              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),

              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },

              calendarFormat: CalendarFormat.month,

              eventLoader: (day) {
                if (isHoliday(day)) {
                  return ['holiday'];
                }
                return [];
              },

              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),

              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (isHoliday(day)) {
                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return null;
                },
              ),

              enabledDayPredicate: (day) {
                final today = DateTime.now();

                final isPast = day.isBefore(
                  DateTime(today.year, today.month, today.day),
                );

                if (isPast) return false;

                final key = weekdayKey(day);
                final rawData = availability[key];

                if (rawData == null) return false;
                if (rawData is! Map) return false;

                final dayData = rawData;

                return dayData['enabled'] == true;
              },

              onDaySelected: (day, focusedDay) async {

              if (isHoliday(day)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Holiday. Reschedule unavailable'),
                  ),
                );
                return;
              }

              await loadBookedTimes(day);

              setState(() {
                _selectedDay = day;
                _focusedDay = focusedDay;
                _selectedTime = null;
                _showSlots = false;
              });
            },
            ),

            const SizedBox(height: 20),

            const Text(
              'Select new time',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_selectedDay != null && !_showSlots && range != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _showSlots = true;
                    });
                  },
                  child: Text(
                    range,
                    style: const TextStyle(color: kWhite),
                  ),
                ),
              ),

            if (_showSlots)
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
                  final selected = time == _selectedTime;

                  return ChoiceChip(
                    label: Text(
                      time,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: selected,
                    selectedColor: kPrimaryBlue,
                    onSelected: (_) {
                      setState(() {
                        _selectedTime = time;
                      });
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (_selectedDay != null && _selectedTime != null)
                  ? rescheduleAppointment
                  : null,
                child: const Text(
                  'Confirm Reschedule',
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