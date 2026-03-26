import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEditDoctorAvailability extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> availability;

  const AdminEditDoctorAvailability({
    super.key,
    required this.doctorId,
    required this.availability,
  });

  @override
  State<AdminEditDoctorAvailability> createState() =>
      _AdminEditDoctorAvailabilityState();
}

class _AdminEditDoctorAvailabilityState
    extends State<AdminEditDoctorAvailability> {

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  final List<String> days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  late Map<String, dynamic> _availability;

  @override
  void initState() {
    super.initState();

    _availability = {};

    for (final day in days) {
      final existing = widget.availability[day];

      if (existing is Map) {
        _availability[day] = {
          'enabled': existing['enabled'] ?? true,
          'start': existing['start'] ?? '09:00 AM',
          'end': existing['end'] ?? '05:00 PM',
        };
      } else {
        _availability[day] = {
          'enabled': false,
          'start': '09:00 AM',
          'end': '05:00 PM',
        };
      }
    }
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctorId)
        .update({'availability': _availability});

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<String?> pickTime(String current) async {
    final parsed = TimeOfDay(
      hour: int.parse(current.split(':')[0]),
      minute: int.parse(current.split(':')[1].split(' ')[0]),
    );

    final result = await showTimePicker(
      context: context,
      initialTime: parsed,
    );

    if (result == null) return null;

    final hour = result.hourOfPeriod == 0 ? 12 : result.hourOfPeriod;
    final minute = result.minute.toString().padLeft(2, '0');
    final period = result.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  Widget _dayCard(String day) {
    final dayData = _availability[day];
    final bool enabled = dayData['enabled'] ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                activeColor: kPrimaryBlue,
                onChanged: (value) {
                  setState(() {
                    _availability[day]['enabled'] = value;
                  });
                },
              ),
            ],
          ),

          if (enabled) ...[
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time =
                          await pickTime(_availability[day]['start']);
                      if (time != null) {
                        setState(() {
                          _availability[day]['start'] = time;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text('Start'),
                          Text(
                            _availability[day]['start'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time =
                          await pickTime(_availability[day]['end']);
                      if (time != null) {
                        setState(() {
                          _availability[day]['end'] = time;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text('End'),
                          Text(
                            _availability[day]['end'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Availability',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: GridView.builder(
                    itemCount: days.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2.5,
                    ),
                    itemBuilder: (context, index) {
                      return _dayCard(days[index]);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Availability'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}