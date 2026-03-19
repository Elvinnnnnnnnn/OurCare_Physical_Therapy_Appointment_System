import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
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

  /// LOAD APPOINTMENTS
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

  /// LOAD HOLIDAYS (PH API)
  Future<void> loadHolidays() async {
    final year = DateTime.now().year;

    final response = await http.get(
      Uri.parse(
          "https://date.nager.at/api/v3/PublicHolidays/$year/PH"),
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

  Color statusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'completed') return Colors.grey;
    if (status == 'cancelled') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents =
        getEventsForDay(_selectedDay ?? DateTime.now());

    return Scaffold(
      backgroundColor: kWhite,
      body: Column(
        children: [

          /// CALENDAR
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,

            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),

            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },

            calendarFormat: CalendarFormat.month,

            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay, day),

            eventLoader: (day) {
              return getEventsForDay(day);
            },

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
                      style:
                          const TextStyle(color: Colors.white),
                    ),
                  );
                }
                return null;
              },
            ),

            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),

          const SizedBox(height: 10),

          /// TITLE
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Appointments',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kDarkBlue,
                ),
              ),
            ),
          ),

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
                      final appt = selectedEvents[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [

                            /// DOCTOR INITIAL
                            CircleAvatar(
                              backgroundColor: kPrimaryBlue.withOpacity(0.1),
                              child: Text(
                                (appt['doctorName'] ?? 'D')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: kPrimaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// DETAILS
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appt['doctorName'] ?? 'Doctor',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${appt['patientName']} • ${appt['time']}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),

                            /// STATUS TEXT
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusText(appt['status']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}