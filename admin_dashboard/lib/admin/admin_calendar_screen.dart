import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  State<AdminCalendarScreen> createState() =>
      _AdminCalendarScreenState();
}

class _AdminCalendarScreenState
    extends State<AdminCalendarScreen> {

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Map<String, dynamic>>> events = {};
  List<DateTime> holidays = [];

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  Widget _appointmentCard(Map<String, dynamic> appt) {

  final doctor = (appt['doctorName'] ?? 'D').toString();
  final patient = (appt['patientName'] ?? '').toString();
  final time = (appt['time'] ?? '').toString();
  final status = _statusText(appt['status']);

  final initial = doctor.isNotEmpty ? doctor[0].toUpperCase() : 'D';

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      children: [

        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: kPrimaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                patient,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14),
                  const SizedBox(width: 4),
                  Text(time, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  void initState() {
    super.initState();
    loadAppointments();
    loadHolidays();
  }

  String _statusText(String? status) {
    if (status == 'approved') return 'Ongoing';
    if (status == 'completed') return 'Completed';
    if (status == 'cancelled') return 'Cancelled';
    return 'Pending';
  }

  Future<void> loadAppointments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .get();

    Map<DateTime, List<Map<String, dynamic>>> temp = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final Timestamp? ts = data['dateTime'];
      if (ts == null) continue;

      final date = ts.toDate();
      final cleanDate =
          DateTime(date.year, date.month, date.day);

      temp.putIfAbsent(cleanDate, () => []);
      temp[cleanDate]!.add(data);
    }

    setState(() {
      events = temp;
    });
  }

  Future<void> loadHolidays() async {
    final year = DateTime.now().year;

    final response = await http.get(
      Uri.parse("https://date.nager.at/api/v3/PublicHolidays/$year/PH"),
    );

    final data = jsonDecode(response.body);

    holidays = data.map<DateTime>((holiday) {
      return DateTime.parse(holiday['date']);
    }).toList();

    setState(() {});
  }

  bool isHoliday(DateTime day) {
    return holidays.any((holiday) =>
        holiday.year == day.year &&
        holiday.month == day.month &&
        holiday.day == day.day);
  }

  List<Map<String, dynamic>> getEventsForDay(DateTime day) {
    final cleanDay =
        DateTime(day.year, day.month, day.day);
    return events[cleanDay] ?? [];
  }

 @override
Widget build(BuildContext context) {
  final selectedEvents =
      getEventsForDay(_selectedDay ?? DateTime.now());

  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// CALENDAR CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,

            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay, day),

            eventLoader: (day) => getEventsForDay(day),

            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: kPrimaryBlue,
                shape: BoxShape.circle,
              ),
            ),

            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();

                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: kPrimaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },

              defaultBuilder: (context, day, _) {
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

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
        ),

        const SizedBox(height: 20),

        /// HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${selectedEvents.length} items',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// LIST
        Expanded(
          child: selectedEvents.isEmpty
              ? const Center(
                  child: Text(
                    'No appointments',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    return _appointmentCard(selectedEvents[index]);
                  },
                ),
        ),
      ],
    ),
  );
}
}