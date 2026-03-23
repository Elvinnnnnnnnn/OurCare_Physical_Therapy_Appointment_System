import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'customer_home.dart';
import 'payment_screen.dart';
import '../services/notification_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  List<String> _selectedTimes = [];
  bool _showSlots = false;
  List<String> bookedTimes = [];

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

    List<DateTime> holidays = [];

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

  Future<void> loadBookedTimes(DateTime day) async {

    final date =
        '${day.year}-${day.month}-${day.day}';

    final snapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('date', isEqualTo: date)
        .get();

    bookedTimes = snapshot.docs
        .map((doc) => doc['time'] as String)
        .toList();

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

  Future<String> getDoctorCategoryNames() async {
    final ids = List<String>.from(widget.doctorData['categoryIds'] ?? []);

    if (ids.isEmpty) return 'General';

    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    final names = snapshot.docs.map((e) => e['name']).join(', ');

    return names.isEmpty ? 'General' : names;
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

    if (_selectedDay == null || _selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date & time')),
      );
      return;
    }

    final date =
        '${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}';

    for (final time in _selectedTimes) {

      final existing = await FirebaseFirestore.instance
          .collection('payments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .get();

      if (existing.docs.isNotEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$time is already booked')),
        );

        return;
      }
    }

    final doctor = widget.doctorData;
    final categoryName = await getDoctorCategoryNames();
    final price = doctor['consultationPrice'] ?? 0;
    final totalAmount = price * _selectedTimes.length;

    String? firstPaymentId;

    final paymentRef =
      await FirebaseFirestore.instance.collection('payments').add({
        'userId': user.uid,
        'doctorId': widget.doctorId,
        'doctorName': doctor['name'],
        'categoryName': categoryName,
        'amount': totalAmount,
        'currency': 'PHP',
        'date': date,
        'times': _selectedTimes, // IMPORTANT (list of times)
        'dateTime': Timestamp.now(),
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

  String _getInitial(String name) {
    if (name.trim().isEmpty) return 'U';
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctorData;
    final price = (doctor['consultationPrice'] ?? 0).toInt();
    final formattedPrice = NumberFormat('#,###').format(price);
    final String doctorName = widget.doctorData['name'] ?? '';
    final String? doctorPhoto = widget.doctorData['photoUrl'];

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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kSoftBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TOP ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (doctorPhoto != null && doctorPhoto.isNotEmpty)
                            ? NetworkImage(doctorPhoto)
                            : null,
                        child: (doctorPhoto == null || doctorPhoto.isEmpty)
                            ? Text(
                                _getInitial(doctorName),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: kDarkBlue,
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// NAME
                            Text(
                              doctor['name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: kDarkBlue,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// CATEGORY
                            FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('categories')
                                  .where(
                                    FieldPath.documentId,
                                    whereIn: List<String>.from(doctor['categoryIds'] ?? []),
                                  )
                                  .get(),
                              builder: (context, snapshot) {

                                if (!snapshot.hasData) {
                                  return const SizedBox();
                                }

                                final names = snapshot.data!.docs
                                    .map((e) => e['name'])
                                    .join(', ');

                                return Text(
                                  names,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                );
                              },
                            ),

                          ],
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.message, color: kPrimaryBlue),
                        onPressed: openChat,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// PRICE (separate, clearer)
                  Row(
                    children: [
                      const Icon(Icons.payments, size: 16, color: kPrimaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        '₱$formattedPrice',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  Text(
                    doctor['aboutMe'] ?? 'No description available',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,

              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

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
                    const SnackBar(content: Text('Holiday. Booking unavailable')),
                  );
                  return;
                }

                await loadBookedTimes(day);

                setState(() {
                  _selectedDay = day;
                  _focusedDay = focusedDay;
                  _selectedTimes.clear();
                  _showSlots = false;
                });
              },
            ),
            const SizedBox(height: 24),

            if (_selectedDay != null && !_showSlots && range != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSoftBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _showSlots = true;
                    });
                  },
                  child: Text(
                    range,
                    style: const TextStyle(
                      color: kDarkBlue,
                      fontWeight: FontWeight.bold,
                    ),
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

                  return ChoiceChip(
                    label: Text(
                      time,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: _selectedTimes.contains(time),
                    selectedColor: kPrimaryBlue,
                    onSelected: (selected) {

                      setState(() {

                        if (selected) {
                          _selectedTimes.add(time);
                        } else {
                          _selectedTimes.remove(time);
                        }

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