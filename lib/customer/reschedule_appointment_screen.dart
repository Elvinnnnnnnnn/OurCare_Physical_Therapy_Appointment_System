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

  @override
  void initState() {
    super.initState();
    loadDoctor();
  }

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

  Map<String, dynamic> get availability {
    final data = doctorData['availability'];

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

  Future<void> loadBookedTimes(DateTime day) async {
    final dateString = '${day.year}-${day.month}-${day.day}';

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId',
            isEqualTo: widget.appointmentData['doctorId'])
        .where('date', isEqualTo: dateString)
        .where('status', whereIn: ['pending', 'approved', 'completed'])
        .get();

    setState(() {
      bookedTimes = snapshot.docs
          .where((doc) => doc.id != widget.appointmentId)
          .map((doc) => doc['time'] as String)
          .toList();
    });
  }

  Future<void> rescheduleAppointment() async {
    if (_selectedDay == null || _selectedTime == null) return;

    final startTime = _selectedTime!.split(' - ').first;
    final parsed = DateFormat('hh:mm a').parse(startTime);

    final newDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      parsed.hour,
      parsed.minute,
    );

    if (bookedTimes.contains(_selectedTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This time slot is already booked'),
        ),
      );
      return;
    }

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

            const SizedBox(height: 20),

            const Text(
              'Select new time',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: times.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
              ),
              itemBuilder: (context, index) {
                final time = times[index];
                final isBooked = bookedTimes.contains(time);
                final selected = time == _selectedTime;

                return ChoiceChip(
                  label: Text(
                    isBooked ? '$time (Booked)' : time,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: selected,
                  selectedColor: kPrimaryBlue,
                  disabledColor: Colors.grey.shade300,
                  onSelected: isBooked
                      ? null
                      : (_) => setState(() => _selectedTime = time),
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