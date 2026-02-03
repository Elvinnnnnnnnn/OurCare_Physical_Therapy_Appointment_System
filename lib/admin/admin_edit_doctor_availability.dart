import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  late Map<String, List<Map<String, String>>> _availability;

  final List<String> days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    _availability = {};

    for (final day in days) {
      final rawSlots = widget.availability[day];

      if (rawSlots == null || rawSlots is! List) {
        _availability[day] = [];
      } else {
        _availability[day] = rawSlots.map<Map<String, String>>((slot) {
          final map = Map<String, dynamic>.from(slot);
          return {
            'start': map['start']?.toString() ?? '',
            'end': map['end']?.toString() ?? '',
          };
        }).toList();
      }
    }
  }

  /// 🔒 OVERLAP CHECK (UNCHANGED)
  bool _hasOverlap(
    String day,
    TimeOfDay newStart,
    TimeOfDay newEnd,
  ) {
    int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

    final newStartMin = toMinutes(newStart);
    final newEndMin = toMinutes(newEnd);

    for (final slot in _availability[day]!) {
      if (slot['start']!.isEmpty || slot['end']!.isEmpty) continue;

      final start =
          DateFormat('hh:mm a').parse(slot['start']!);
      final end =
          DateFormat('hh:mm a').parse(slot['end']!);

      final startMin = start.hour * 60 + start.minute;
      final endMin = end.hour * 60 + end.minute;

      if (newStartMin < endMin && newEndMin > startMin) {
        return true;
      }
    }
    return false;
  }

  Future<void> _pickTime(
    String day,
    int index,
    bool isStart,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked == null) return;

    setState(() {
      _availability[day]![index]
          [isStart ? 'start' : 'end'] =
          picked.format(context);
    });
  }

  /// ➕ ADD TIME RANGE
  Future<void> _addTimeRange(String day) async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (end == null) return;

    if (_hasOverlap(day, start, end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Time overlaps with existing schedule'),
        ),
      );
      return;
    }

    setState(() {
      _availability[day]!.add({
        'start': start.format(context),
        'end': end.format(context),
      });
    });
  }

  /// ❌ DELETE TIME RANGE (NEW – SIMPLE & SAFE)
  void _deleteTime(String day, int index) {
    setState(() {
      _availability[day]!.removeAt(index);
    });
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctorId)
        .update({'availability': _availability});

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Availability'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: days.map((day) {
          final slots = _availability[day]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// DAY HEADER
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          day.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: slots.isNotEmpty,
                        onChanged: (value) {
                          setState(() {
                            if (value) {
                              // 🔑 TURN ON → ADD EMPTY SLOT
                              if (slots.isEmpty) {
                                slots.add({
                                  'start': '',
                                  'end': '',
                                });
                              }
                            } else {
                              // 🔑 TURN OFF → CLEAR
                              slots.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),

                  if (slots.isNotEmpty)
                    Column(
                      children: [
                        ...List.generate(slots.length, (i) {
                          return Row(
                            children: [
                              TextButton(
                                onPressed: () =>
                                    _pickTime(day, i, true),
                                child:
                                    Text(slots[i]['start']!),
                              ),
                              const Text(' – '),
                              TextButton(
                                onPressed: () =>
                                    _pickTime(day, i, false),
                                child:
                                    Text(slots[i]['end']!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    _deleteTime(day, i),
                              ),
                            ],
                          );
                        }),

                        /// ➕ ADD TIME BUTTON
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Time'),
                            onPressed: () =>
                                _addTimeRange(day),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _save,
          child: const Text('Save Availability'),
        ),
      ),
    );
  }
}
