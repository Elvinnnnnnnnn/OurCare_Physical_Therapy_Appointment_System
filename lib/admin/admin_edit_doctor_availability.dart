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

  final List<Map<String, dynamic>> defaultSlots = [
    {'start': '08:00 AM', 'end': '09:00 AM', 'active': true},
    {'start': '10:00 AM', 'end': '11:00 AM', 'active': true},
    {'start': '12:00 PM', 'end': '01:00 PM', 'active': true},
    {'start': '02:00 PM', 'end': '03:00 PM', 'active': true},
    {'start': '04:00 PM', 'end': '05:00 PM', 'active': true},
  ];

  @override
  void initState() {
    super.initState();

    _availability = {};

    for (final day in days) {
      final existing = widget.availability[day];

      // OLD FORMAT
      if (existing is List) {
        _availability[day] = {
          'enabled': true,
          'slots': existing.map((slot) {
            final map = Map<String, dynamic>.from(slot);
            return {
              'start': map['start'],
              'end': map['end'],
              'active': true,
            };
          }).toList(),
        };
      }

      // NEW FORMAT
      else if (existing is Map) {
        final List rawSlots = existing['slots'] ?? [];

        _availability[day] = {
          'enabled': existing['enabled'] ?? true,
          'slots': rawSlots.isEmpty
              ? List<Map<String, dynamic>>.from(defaultSlots)
              : rawSlots.map((slot) {
                  final map = Map<String, dynamic>.from(slot);
                  return {
                    'start': map['start'],
                    'end': map['end'],
                    'active': map['active'] ?? true,
                  };
                }).toList(),
        };
      }

      // NO DATA
      else {
        _availability[day] = {
          'enabled': true,
          'slots': List<Map<String, dynamic>>.from(defaultSlots),
        };
      }
    }
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
      appBar: AppBar(title: const Text('Edit Availability')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: days.map((day) {
          final dayData = _availability[day];
          final bool enabled = dayData['enabled'] ?? true;
          final List slots =
              List<Map<String, dynamic>>.from(dayData['slots']);

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
                        value: enabled,
                        onChanged: (value) {
                          setState(() {
                            _availability[day]['enabled'] = value;
                          });
                        },
                      ),
                    ],
                  ),

                  if (enabled)
                    Column(
                      children: slots.map((slot) {
                        return Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${slot['start']} - ${slot['end']}',
                            ),
                            Switch(
                              value: slot['active'] ?? true,
                              onChanged: (value) {
                                setState(() {
                                  slot['active'] = value;
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
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