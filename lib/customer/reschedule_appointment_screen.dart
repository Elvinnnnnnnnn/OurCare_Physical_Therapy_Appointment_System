import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  const RescheduleAppointmentScreen({
    super.key,
    required this.appointmentId,
    required this.appointmentData,
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

  List<String> bookedTimes = [];

  Map<String, dynamic> doctorData = {};
  bool loadingDoctor = true;

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  final List<String> fallbackTimes = [
    '09:00 AM – 10:00 AM',
    '12:00 PM – 01:00 PM',
    '04:00 PM – 05:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    loadDoctor();
  }

  /// 🔥 LOAD DOCTOR DATA (SOURCE OF TRUTH)
  Future<void> loadDoctor() async {
    final doctorId = widget.appointmentData['doctorId'];

    final doc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();

    if (doc.exists) {
      setState(() {
        doctorData = doc.data()!;
        loadingDoctor = false;
      });
    }
  }

  /// 🔑 DOCTOR AVAILABILITY (SAME AS DoctorDetailsScreen)
  Map<String, dynamic> get availability {
    final data = doctorData['availability'];
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

  /// 🔥 LOAD BOOKED TIMES
  Future<void> loadBookedTimes(DateTime day) async {
    final dateString = '${day.year}-${day.month}-${day.day}';

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId',
            isEqualTo: widget.appointmentData['doctorId'])
        .where('date', isEqualTo: dateString)
        .get();

    setState(() {
      bookedTimes =
          snapshot.docs.map((doc) => doc['time'] as String).toList();
    });
  }

  /// 🔄 RESCHEDULE
  Future<void> rescheduleAppointment() async {
    if (_selectedDay == null || _selectedTime == null) return;

    final startTime = _selectedTime!.split(' – ').first;
    final parsed = DateFormat('hh:mm a').parse(startTime);

    final newDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      parsed.hour,
      parsed.minute,
    );

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .update({
      'date':
          '${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}',
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

            /// 📅 CALENDAR (SAME RULES AS DOCTOR DETAILS)
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 60)),
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
                loadBookedTimes(day);
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Select new time',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: times.map((time) {
                final isBooked = bookedTimes.contains(time);
                final selected = time == _selectedTime;

                return ChoiceChip(
                  label: Text(time),
                  selected: selected,
                  selectedColor: kPrimaryBlue,
                  onSelected: isBooked
                      ? null
                      : (_) =>
                          setState(() => _selectedTime = time),
                  labelStyle: TextStyle(
                    color: selected ? kWhite : kDarkBlue,
                  ),
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
                ),
                onPressed: rescheduleAppointment,
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
